//
//  SessionController.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "SessionController.h"
#import "GameManager.h"
#import "Message.h"
#import "MPIEventLogger.h"
#import <CommonCrypto/CommonDigest.h>

@interface MPISessionController () // Class extension

@property (readwrite) MPILocalSessionState mySessionState;  // track state of managed MCSession
@property (readwrite) MPIPeerState myPeerState;             // track state of local peer

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *serviceBrowser;

// timer for initial advertise ...
@property (nonatomic, strong) NSTimer* advertiseTimer;

// track start time of invitation process for specific peers
@property (nonatomic, strong) NSMutableDictionary* invitations;

@end

@implementation MPISessionController

static NSString * const kLogDefaultTag = @"SessionController";
static NSString * const kLocalPeerIDKey = @"mpi-local-peerid";
static NSString * const kMCSessionServiceType = @"mpi-shared";

static double const kInitialAdvertiseSeconds = 7.0f;

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _mySessionState = MPILocalSessionStateNotCreated;
        
        // capture function name for event logging
        NSString* source = [[NSString alloc] initWithUTF8String:__PRETTY_FUNCTION__];
        
        // check if this device has a saved peer ID
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSData *peerIDData = [userDefaults dataForKey:kLocalPeerIDKey];
        if (peerIDData == nil) {
            // create and store once
            //
            // TODO: get this using JBDeviceOwner or similar on first launch
            _peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
            // save to user defaults
            NSData *peerIDData = [NSKeyedArchiver archivedDataWithRootObject:_peerID];
            [userDefaults setObject:peerIDData forKey:kLocalPeerIDKey];
            [userDefaults synchronize];
            
            [[MPIEventLogger sharedInstance] log:source description:@"created and saved peerID"];
        } else {
            // get existing peerID from defaults
            _peerID = [NSKeyedUnarchiver unarchiveObjectWithData:peerIDData];
            
            [[MPIEventLogger sharedInstance] log:source description:@"retrieved existing peerID"];
        }
        
        
        _invitations = [[NSMutableDictionary alloc] init];
        
        _displayName = _peerID.displayName;
    }
    
    return self;
}


#pragma mark - Memory management

- (void)dealloc
{
    // Unregister for notifications on deallocation.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Nil out delegates
    _session.delegate = nil;
    _serviceAdvertiser.delegate = nil;
    _serviceBrowser.delegate = nil;
}

#pragma mark - Public methods

- (void)sendTimestamp:(MCPeerID*)peer{
    // call overriden method
    [self sendTimestamp:[[NSNumber alloc] initWithDouble:[[NSDate date] timeIntervalSince1970]] toPeer:peer];
}
- (void)sendTimestamp:(NSNumber*)time toPeer:(MCPeerID*)peer{
    // call overriden method
    [self sendMessage:@"4" value:time toPeer:peer];
}

- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeer:(MCPeerID*)peer {
    [self sendMessage:type value:val toPeer:peer asReliable:YES];
}
- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeer:(MCPeerID*)peer asReliable:(BOOL)reliable {
    
    // convert single peer to array
    NSArray *peers = [[NSArray alloc] initWithObjects:peer, nil];
    
    // call overriden method
    [self sendMessage:type value:val toPeers:peers asReliable:reliable];
}

- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeers:(NSArray *)peers{
    [self sendMessage:type value:val toPeers:peers asReliable:YES];
}
- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeers:(NSArray *)peers asReliable:(BOOL)reliable {
    NSDate* sendDt = [NSDate date];
    // create message object
    MPIMessage *msg = [[MPIMessage alloc] init];
    msg.type = type;
    msg.val = val;
    msg.createdAt = [[MPIEventLogger sharedInstance] timeWithOffset:sendDt];

    // use override
    [self sendMessage:msg toPeers:peers];
}

- (void) sendMessage:(id)msg toPeer:(MCPeerID *)peer {
    // convert single peer to array
    NSArray *peers = [[NSArray alloc] initWithObjects:peer, nil];
    
    // call overriden method
    [self sendMessage:msg toPeers:peers];
}

- (void) sendMessage:(id)msg toPeers:(NSArray *)peers {
    [self sendMessage:msg toPeers:peers asReliable:YES];
}
- (void) sendMessage:(id)msg toPeers:(NSArray *)peers asReliable:(BOOL)reliable {
     
    // serialize as JSON dictionary
    NSDictionary* json = [MTLJSONAdapter JSONDictionaryFromModel:msg];
    
    // convert to data object
    NSData *msgData = [NSKeyedArchiver archivedDataWithRootObject:[json copy]];
    NSError *error;
    // send message to specified peers ... using current session
    if (![self.session sendData:msgData
                        toPeers:peers
                       withMode:(reliable ? MCSessionSendDataReliable : MCSessionSendDataUnreliable)
                          error:&error]) {
        MPIError(@"[Error] sending data %@", error);
        // if code is 1, then peer is not reachable
        //
        // TODO: how to handle case of single peer causing error?
        //
        if (error.code == 1) {
            for ( int i = 0; i < peers.count; i++) {
                [self.delegate peer:peers[i] didChangeState:MPIPeerStateDisconnected];
            }
        }
        
        // don't continue if there was an error
        return;
    }
    
    // log to server
    NSString* source = [[NSString alloc] initWithUTF8String:__PRETTY_FUNCTION__];
    [[MPIEventLogger sharedInstance] log:MPILoggerLevelInfo
                                  source:source
                             description:@"sending message"
                                    tags:[[NSArray alloc] initWithObjects:@"Message", nil]
                                   start:[NSDate date]
                                     end:nil
                                    data:json];
}


#pragma mark - Start or Stop session controller

- (void)startup
{
    // Create the session that peers will be invited/join into.
    _session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
    
    MPIDebug(@"created session for peerID: %@", self.peerID.displayName);
    
    // update local state
    _mySessionState = MPILocalSessionStateCreated;
    

    // advertise for a bit
    [self startAdvertising];
    // then switch to browse if no invite was received after
    _advertiseTimer = [NSTimer scheduledTimerWithTimeInterval:kInitialAdvertiseSeconds target:self
                                           selector:@selector(advertiseTimedOut:) userInfo:nil repeats:NO];

    
}

- (void) advertiseTimedOut:(NSTimer *)incomingTimer
{
    MPIDebug(@"Advertise timed out, starting browser.");
    // if invitation was not recieved ... and therefore the timer cancelled
    // then stop advertising and start browsing
    [self stopAdvertising];
    [self startBrowsing];
}

- (void)shutdown
{
    MPIDebug(@"teardown session for peerID: %@", self.peerID.displayName);
    
    [self.session disconnect];
    
    // clear out advertiser and browser ... if created
    _serviceBrowser = nil;
    _serviceAdvertiser = nil;
    
    // update local state
    _mySessionState = MPILocalSessionStateNotCreated;
}

#pragma mark - Control advertising and browsing

// advertiser and browser controller
- (void)startAdvertising
{
    // Create the service advertiser ... if not yet created
    if (_serviceAdvertiser == nil) {
        _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID
                                                               discoveryInfo:nil
                                                                 serviceType:kMCSessionServiceType];
        self.serviceAdvertiser.delegate = self;
        
        MPIDebug(@"created advertiser for peerID: %@", self.peerID.displayName);
    }
    
    NSLog(@"startAdvertising");
    [self.serviceAdvertiser startAdvertisingPeer];
    
    _mySessionState = MPILocalSessionStateAdvertising;
}
- (void)stopAdvertising
{
    MPIDebug(@"stopAdvertising");
    if (_serviceAdvertiser != nil) { [self.serviceAdvertiser stopAdvertisingPeer]; }
    
    // TODO: double check appropriate next state on advertise stop
    _mySessionState = MPILocalSessionStateNotAdvertising;
}
- (void)startBrowsing
{
    // Create the service browser ... if not yet created
    if (_serviceBrowser == nil) {
        _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID
                                                           serviceType:kMCSessionServiceType];
        self.serviceBrowser.delegate = self;
        
        MPIDebug(@"created browser for peerID: %@", self.peerID.displayName);
    }
    
    MPIDebug(@"startBrowsing");
    [self.serviceBrowser startBrowsingForPeers];
    
    _mySessionState = MPILocalSessionStateBrowsing;
}
- (void)stopBrowsing
{
    MPIDebug(@"stopBrowsing");
    if (_serviceBrowser != nil) { [self.serviceBrowser stopBrowsingForPeers]; }
    
    // TODO: double check appropriate next state on browsing stop
    _mySessionState = MPILocalSessionStateNotBrowsing;
}

#pragma mark - MCSessionDelegate protocol conformance

// See: http://stackoverflow.com/questions/18935288/why-does-my-mcsession-peer-disconnect-randomly
- (void) session:(MCSession*)session didReceiveCertificate:(NSArray*)certificate fromPeer:(MCPeerID*)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    if (certificateHandler != nil) { certificateHandler(YES); }
}

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    
    MPIDebug(@"Peer [%@] changed state to %@.  There are now %lu connected.", peerID.displayName, [self stringForPeerConnectionState:state], (unsigned long)self.session.connectedPeers.count);
    
    switch (state)
    {
        case MCSessionStateConnecting:
        {
            [self.delegate peer:peerID didChangeState:MPIPeerStateDiscovered];
            break;
        }
            
        case MCSessionStateConnected:
        {
            NSDate* inviteBeganAt = _invitations[peerID.displayName];
            if (inviteBeganAt != nil) {
                NSArray* tags = [[NSArray alloc] initWithObjects:@"Invite", nil];
                NSString* description = [NSString stringWithFormat:@"Finished invite process with %@.", peerID.displayName];
                [[MPIEventLogger sharedInstance] info:@"Invitation" description:description tags:tags start:inviteBeganAt end:[[NSDate alloc] init]];
                
                // initiate time sync & save self as time server
                _timeServerPeerID = _peerID;
                [[MPIGameManager instance] requestTimeSync:peerID value:0];
                
                // change peer state to time syncing
                [self.delegate peer:peerID didChangeState:MPIPeerStateSyncingTime];
                
            } else {
                // change peer state to inite accepted
                [self.delegate peer:peerID didChangeState:MPIPeerStateInviteAccepted];
            }
            
            // check if local session state should change to created
            if (self.session.connectedPeers.count > 0) {
                _mySessionState = MPILocalSessionStateConnected;
            }
            break;
        }
            
        case MCSessionStateNotConnected:
        {
            // update peer connection status
            [self.delegate peer:peerID didChangeState:MPIPeerStateDisconnected];
            
            // check if local session state should fall back to created
            if (self.session.connectedPeers.count <= 0) {
                _mySessionState = MPILocalSessionStateCreated;
            }
            break;
        }
    }
    
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)nearbyPeerID
{
    // first unarchive
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    //
    // HACK, HACK, HACKY
    //
    // then deserialize as from JSON if NSDictionary
    if ([obj isKindOfClass:[NSDictionary class]]){
        
        NSString *msgType = obj[@"type"];
        // NEW: Log Message recieve event
        NSString* source = [[NSString alloc] initWithUTF8String:__PRETTY_FUNCTION__];
        NSString* action = @"UNKOWN";
        if ([msgType isEqualToString:@"1"]) {
            action = @"Flash";
        } else if ([msgType isEqualToString:@"2"]) {
            action = @"Volume";
        } else if ([msgType isEqualToString:@"4"]) {
            action = @"Time";
        } else if ([msgType isEqualToString:@"5"]) {
            action = @"Sync Request";
        } else if ([msgType isEqualToString:@"6"]) {
            action = @"Song Info";
        } else if ([msgType isEqualToString:@"7"]) {
            action = @"Recording play/stop";
        } else if ([msgType isEqualToString:@"8"]) {
            action = @"Heartbeat";
        }
        NSDate* start = [[MPIMessage dateFormatter] dateFromString:obj[@"createdAt"]];
        NSDate* end = [NSDate date];
        
        NSString* description = [NSString stringWithFormat:@"%@ sent %@", nearbyPeerID.displayName, action];
        NSArray* tags = [[NSArray alloc] initWithObjects:@"Message", action, nil];
        //MPIEventPersistence status =
        [[MPIEventLogger sharedInstance] debug:source description:description tags:tags start:start end:end data:obj];
        
        // handle sync and time messages differently
        if([action isEqualToString:@"Sync Request"]) {
            
            // save reference to peer which initiated sync
            _timeServerPeerID = nearbyPeerID;
            
            // initiate time sync with requestor
            [[MPIGameManager instance] calculateTimeDeltaFrom:nearbyPeerID];
            
            [self.delegate peer:nearbyPeerID didChangeState:MPIPeerStateSyncingTime];
            
        } else if([action isEqualToString:@"Time"]) {
            //
            // DANGER: what if peers have the same display name
            if ([_timeServerPeerID.displayName isEqualToString:_peerID.displayName]) {
                // this is the time server ... so just reply with timestamp
                [self sendTimestamp:nearbyPeerID];
                
            } else {
                // this is peer that is requesting sync
                BOOL isDone = [[MPIGameManager instance] recievedTimestamp:nearbyPeerID value:0];
                if (isDone) {
                    [self.delegate peer:nearbyPeerID didChangeState:MPIPeerStateConnected];
                    
                    // now start heartbeat
                    [[MPIGameManager instance] startHeartbeatWithPeer:nearbyPeerID];
                }
                
            }
        } else {
            // default is to let the game manager handle the message
            [[MPIGameManager instance] handleActionRequest:obj type:msgType fromPeer:nearbyPeerID];
        }
        
    }
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    MPIDebug(@"didStartReceivingResourceWithName [%@] from %@ with progress [%@]", resourceName, peerID.displayName, progress);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)fromPeerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    MPIDebug(@"didFinishReceivingResourceWithName [%@] from %@", resourceName, fromPeerID.displayName);
    
    // If error is not nil something went wrong
    if (error)
    {
        MPIError(@"Error [%@] receiving resource from %@ ", [error localizedDescription], fromPeerID.displayName);
    }
    else
    {
        // No error so this is a completed transfer.
        // The resources is located in a temporary location and should be copied to a permenant location immediately.
        // Write to documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths firstObject], resourceName];
        NSError* error;
        
        
        //
        // TODO: verify this works if the file does not exist yet
        //
        NSURL* resultingURL;
        if (![[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:copyPath] withItemAtURL:localURL backupItemName:@"audiofile-backup" options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingURL error:&error])
        {
            MPIError(@"Error copying resource to documents directory (%@) [%@]", copyPath, error);
        }
        else
        {
            // Get a URL for the path we just copied the resource to
            MPIDebug(@"url = %@, copyPath = %@", resultingURL, copyPath);
            
            // tell game manager about it .. should use self ID ... since it was for self
            [self.delegate session:self didReceiveAudioFileFrom:_peerID.displayName atPath:copyPath];
        }
    }
}

// Streaming API not utilized in this sample code
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    MPIDebug(@"didReceiveStream %@ from %@", streamName, peerID.displayName);
    if ([streamName isEqualToString:@"mic"]) {
        [self.delegate session:self didReceiveAudioStream:stream];
    } else if ([streamName isEqualToString:@"audio-file"]) {
        [self.delegate session:self didReceiveAudioFileStream:stream];
    }
}

- (NSOutputStream *)outputStreamForPeer:(MCPeerID *)peer withName:(NSString*)streamName
{
    NSError *error;
    NSOutputStream *stream = [self.session startStreamWithName:streamName toPeer:peer error:&error];
    
    if (error) {
        MPIError(@"Error: %@", [error userInfo].description);
    }
    
    return stream;
}

- (void)sendAudioFileAtPath:(NSString*)filePath toPeer:(id)peerID
{
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    MPIDebug(@"Attempting send for file at %@", filePath);
    
    //
    // TODO: hookup progress to UI
    //
    NSProgress *progress =
        [self.session sendResourceAtURL:fileURL
                               withName:[fileURL lastPathComponent]
                                 toPeer:peerID
                  withCompletionHandler:^(NSError *error)
        {
            if (error) { MPIError(@"[Error sending audio file] %@", error); return; }
            MPIDebug(@"Done sending file: %@", filePath);
        }];
}

#pragma mark - MCNearbyServiceBrowserDelegate protocol conformance

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)nearbyPeerID withDiscoveryInfo:(NSDictionary *)info
{
    NSString *remotePeerName = nearbyPeerID.displayName;
    MPIDebug(@"Browser found nearbyPeer (name: %@)", remotePeerName);
    [self.delegate peer:nearbyPeerID didChangeState:MPIPeerStateDiscovered];
    
    //
    // TODO: are there other condition under which invitation should not be sent??
    //
    if (self.session != nil && _mySessionState != MPILocalSessionStateNotCreated) {
        MPIDebug(@"Inviting %@", remotePeerName);
        
        // save invitation start for this peer
        _invitations[remotePeerName] = [[NSDate alloc] init];
        
        [browser invitePeer:nearbyPeerID toSession:self.session withContext:nil timeout:20.0];
        
        [self.delegate peer:nearbyPeerID didChangeState:MPIPeerStateInvited];
    }
    else {
        MPIDebug(@"Session not ready. Not inviting foundPeer: %@", remotePeerName);
    }
}

- (NSString*)printSessionConnectedPeers
{
    NSString* output = @"";
    for (int i = 0; i < self.session.connectedPeers.count; i++) {
        MCPeerID* peerID = self.session.connectedPeers[i];
        output = [output stringByAppendingString:peerID.displayName];
    }
    return output;
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    MPIDebug(@"lostPeer %@. session.connectedPeers: %@", peerID.displayName, [self printSessionConnectedPeers]);
    
    // update peer connection state
    [self.delegate peer:peerID didChangeState:MPIPeerStateDisconnected];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    MPIDebug(@"didNotStartBrowsingForPeers: %@", error);
    
    _mySessionState = MPILocalSessionStateNotBrowsing;
}

#pragma mark - MCNearbyServiceAdvertiserDelegate protocol conformance

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    MPIDebug(@"didReceiveInvitationFromPeer %@", peerID.displayName);
    
    // cancel advertise timer on receipt of invitation
    [_advertiseTimer invalidate];
    
    //
    // Only accept if not already in session.
    // This is to prevent multiple networks from being created.
    //
    
    if (self.session.connectedPeers.count == 0) {
        invitationHandler(YES, self.session);
        // update peer state
        [self.delegate peer:peerID didChangeState:MPIPeerStateInviteAccepted];
    } else {
        MPIDebug(@"NOT accepting invitation from %@ since there are already %lu connected peers.", peerID.displayName, (unsigned long)self.session.connectedPeers.count);
        invitationHandler(NO, self.session);
        // update peer state
        [self.delegate peer:peerID didChangeState:MPIPeerStateInviteDeclined];
    }

}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    MPIWarn(@"didNotStartAdvertisingForPeers: %@", error);
    
    _mySessionState = MPILocalSessionStateNotAdvertising;
}

//
// TODO: get rid of this .. only used for logging
//
- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";
            
        case MCSessionStateConnecting:
            return @"Connecting";
            
        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}

@end
