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
@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *serviceAdvertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *serviceBrowser;

// Connected peers are stored in the MCSession
// Manually track connecting and disconnected peers
@property (nonatomic, strong) NSMutableOrderedSet *connectingPeersOrderedSet;
@property (nonatomic, strong) NSMutableOrderedSet *disconnectedPeersOrderedSet;
@end

@implementation MPISessionController

static NSString * const kLogSource = @"SessionController";
static NSString * const kLocalPeerIDKey = @"mpi-local-peerid";
static NSString * const kMCSessionServiceType = @"mpi-shared";

#pragma mark - Initializer

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
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
            
            [[MPIEventLogger instance] log:kLogSource description:@"created and saved peerID"];
        } else {
            // get existing peerID from defaults
            _peerID = [NSKeyedUnarchiver unarchiveObjectWithData:peerIDData];
            
            [[MPIEventLogger instance] log:kLogSource description:@"retrieved existing peerID"];
        }
        
        
        _connectingPeersOrderedSet = [[NSMutableOrderedSet alloc] init];
        _disconnectedPeersOrderedSet = [[NSMutableOrderedSet alloc] init];
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        
        // Register for notifications
        [defaultCenter addObserver:self
                          selector:@selector(startServices)
                              name:UIApplicationWillEnterForegroundNotification
                            object:nil];
        
        [defaultCenter addObserver:self
                          selector:@selector(stopServices)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
        
        [self startServices];
        
        _connectedPeers = self.session.connectedPeers;
        _connectingPeers = [self.connectingPeersOrderedSet array];
        _disconnectedPeers = [self.disconnectedPeersOrderedSet array];
        
        _displayName = self.session.myPeerID.displayName;
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
- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeer:(MCPeerID*)peer{
    
    // convert single peer to array
    NSArray *peers = [[NSArray alloc] initWithObjects:peer, nil];
    
    // call overriden method
    [self sendMessage:type value:val toPeers:peers];
}

- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeers:(NSArray *)peers{
    // create message object
    MPIMessage *msg = [[MPIMessage alloc] init];
    msg.type = type;
    msg.val = val;
    // serialize as JSON dictionary
    NSDictionary* json = [MTLJSONAdapter JSONDictionaryFromModel:msg];
    
    // convert to data object
    NSData *msgData = [NSKeyedArchiver archivedDataWithRootObject:json];
    
    NSError *error;
    // send message to specified peers ... using current session
    if (![self.session sendData:msgData
                           toPeers:peers
                          withMode:MCSessionSendDataReliable
                             error:&error]) {
        NSLog(@"[Error] sending data %@", error);
    }
    
    // log to server
    [[MPIEventLogger instance] log:MPILoggerLevelInfo
                            source:kLogSource
                       description:@"sending message"
                              tags:[[NSArray alloc] initWithObjects:@"Message", nil]
                             start:[[NSDate alloc]init]
                               end:[[NSDate alloc]init]
                              data:json];
}

#pragma mark - Private methods

- (void)setupSession
{
    
    // Create the session that peers will be invited/join into.
    _session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"created session for peerID: %@", self.peerID.displayName]];
    
    
    // Create the service advertiser
    _serviceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID
                                                           discoveryInfo:nil
                                                             serviceType:kMCSessionServiceType];
    self.serviceAdvertiser.delegate = self;
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"created advertiser for peerID: %@", self.peerID.displayName]];
    
    
    // Create the service browser
    _serviceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID
                                                       serviceType:kMCSessionServiceType];
    self.serviceBrowser.delegate = self;
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"created browser for peerID: %@", self.peerID.displayName]];
    
}

- (void)teardownSession
{
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"teardown session for peerID: %@", self.peerID.displayName]];
    
    [self.session disconnect];
    [self.connectingPeersOrderedSet removeAllObjects];
    [self.disconnectedPeersOrderedSet removeAllObjects];
}

- (void)startServices
{
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"start services for peerID: %@", self.peerID.displayName]];
    
    [self setupSession];
    [self.serviceAdvertiser startAdvertisingPeer];
    [self.serviceBrowser startBrowsingForPeers];
}

- (void)stopServices
{
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"stop services for peerID: %@", self.peerID.displayName]];
    
    [self.serviceBrowser stopBrowsingForPeers];
    [self.serviceAdvertiser stopAdvertisingPeer];
    [self teardownSession];
}

- (void)updateDelegate
{
    _connectedPeers = self.session.connectedPeers;
    _connectingPeers = [self.connectingPeersOrderedSet array];
    _disconnectedPeers = [self.disconnectedPeersOrderedSet array];
    
    [self.delegate sessionDidChangeState];
}

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

#pragma mark - MCSessionDelegate protocol conformance

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"Peer [%@] changed state to %@", peerID.displayName, [self stringForPeerConnectionState:state]]];
    
    switch (state)
    {
        case MCSessionStateConnecting:
        {
            [self.connectingPeersOrderedSet addObject:peerID];
            [self.disconnectedPeersOrderedSet removeObject:peerID];
            break;
        }
            
        case MCSessionStateConnected:
        {
            [self.connectingPeersOrderedSet removeObject:peerID];
            [self.disconnectedPeersOrderedSet removeObject:peerID];
            break;
        }
            
        case MCSessionStateNotConnected:
        {
            [self.connectingPeersOrderedSet removeObject:peerID];
            [self.disconnectedPeersOrderedSet addObject:peerID];
            break;
        }
    }
    
    [self updateDelegate];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    // first unarchive
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    // then deserialize as from JSON if NSDictionary
    if ([obj isKindOfClass:[NSDictionary class]]){
        
        NSError *error = nil;
        MPIMessage *msg = [MTLJSONAdapter modelOfClass:[MPIMessage class] fromJSONDictionary:obj error:&error];
        
        NSLog(@"didReceiveData %@:%@ from %@", msg.type, msg.val, peerID.displayName);
        
        [[MPIGameManager instance] handleActionRequest:msg.type value:msg.val];
        
    }
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"didStartReceivingResourceWithName [%@] from %@ with progress [%@]", resourceName, peerID.displayName, progress);
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"didFinishReceivingResourceWithName [%@] from %@", resourceName, peerID.displayName);
    
    // If error is not nil something went wrong
    if (error)
    {
        NSLog(@"Error [%@] receiving resource from %@ ", [error localizedDescription], peerID.displayName);
    }
    else
    {
        // No error so this is a completed transfer.
        // The resources is located in a temporary location and should be copied to a permenant location immediately.
        // Write to documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths firstObject], resourceName];
        if (![[NSFileManager defaultManager] copyItemAtPath:[localURL path] toPath:copyPath error:nil])
        {
            NSLog(@"Error copying resource to documents directory");
        }
        else
        {
            // Get a URL for the path we just copied the resource to
            NSURL *url = [NSURL fileURLWithPath:copyPath];
            NSLog(@"url = %@", url);
        }
    }
}

// Streaming API not utilized in this sample code
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"didReceiveStream %@ from %@", streamName, peerID.displayName);
}

#pragma mark - MCNearbyServiceBrowserDelegate protocol conformance

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)nearbyPeerID withDiscoveryInfo:(NSDictionary *)info
{
    NSString *remotePeerName = nearbyPeerID.displayName;
    
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"Browser found (name: %@)", remotePeerName]];
    
    MCPeerID *myPeerID = self.session.myPeerID;
    
    if ([self sha1:myPeerID.displayName] > [self sha1:remotePeerName])
    {
        [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"Inviting %@", remotePeerName]];
        
        [browser invitePeer:nearbyPeerID toSession:self.session withContext:nil timeout:10.0];
    }
    else
    {
        [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"Not inviting(my sha1: %@, remote sha1: %@)", [self sha1:myPeerID.displayName], [self sha1:remotePeerName]]];
    }
    
    [self updateDelegate];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"lostPeer %@", peerID.displayName]];
    
    [self.connectingPeersOrderedSet removeObject:peerID];
    [self.disconnectedPeersOrderedSet addObject:peerID];
    
    [self updateDelegate];
}

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"didNotStartBrowsingForPeers: %@", error]];
}

#pragma mark - MCNearbyServiceAdvertiserDelegate protocol conformance

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"didReceiveInvitationFromPeer %@", peerID.displayName]];
    
    /*
    [UIActionSheet showInView:self.view withTitle:[NSString stringWithFormat:NSLocalizedString(@"Received Invitation from %@", @"Received Invitation from {Peer}"), peerID.displayName]
            cancelButtonTitle:NSLocalizedString(@"Reject", nil)
       destructiveButtonTitle:NSLocalizedString(@"Block", nil)
            otherButtonTitles:@[NSLocalizedString(@"Accept", nil)]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex)
     {
         BOOL acceptedInvitation = (buttonIndex == [actionSheet firstOtherButtonIndex]);
         
         if (buttonIndex == [actionSheet destructiveButtonIndex]) {
             // TODO: allow block
             
             //[self.mutableBlockedPeers addObject:peerID];
         }
         
         invitationHandler(acceptedInvitation, (acceptedInvitation ? self.session : nil));
         
         [self.connectingPeersOrderedSet addObject:peerID];
         [self.disconnectedPeersOrderedSet removeObject:peerID];
         
         [self updateDelegate];
     }];
     */
    
    
    //
    // TODO: Only accept if not already in session
    //
    
    invitationHandler(YES, self.session);
    
    [self.connectingPeersOrderedSet addObject:peerID];
    [self.disconnectedPeersOrderedSet removeObject:peerID];
    
    [self updateDelegate];

}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    [[MPIEventLogger instance] log:kLogSource description:[NSString stringWithFormat:@"didNotStartAdvertisingForPeers: %@", error]];
}

/*
 * A custom hash function is needed since NSString.hash is device/cpu dependent.
 * This sha1 was taken from http://www.makebetterthings.com/iphone/how-to-get-md5-and-sha1-in-objective-c-ios-sdk/
 *
 * @param input - the string to compute a hash for 
 * @return the hashed value
 */
-(NSString*) sha1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (unsigned int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
    
}

@end
