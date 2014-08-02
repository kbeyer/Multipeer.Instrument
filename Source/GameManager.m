//
//  MPIGameManager.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "GameManager.h"
#import "AudioManager.h"
#import "ActionMessage.h"
#import "MPIEventLogger.h"
#import <AVFoundation/AVFoundation.h>

@interface MPIGameManager()
@property (nonatomic, strong) AVCaptureSession *avSession;
@property (nonatomic, strong) MPIAudioManager *audioManager;
@property double lastSendTimestamp;
@property (nonatomic, strong) NSMutableArray *timeLatencies;
@property (nonatomic, strong) NSTimer* heartbeatTimer;
@end


static int const kTimeSyncIterations = 10;
static int const kHearbeatIntervalSeconds = 2;

@implementation MPIGameManager

- (id)init {
    
    self = [super init];
    if (self) {
        // initial configuration
        [self configure];
    }
    return self;
}

- (void)configure {
    
    
    //
    // TODO: refactor into single list with [PeerID, State]
    //
    _connectingPeers = [[NSMutableOrderedSet alloc] init];
    _connectedPeers = [[NSMutableOrderedSet alloc] init];
    _disconnectedPeers = [[NSMutableOrderedSet alloc] init];
    
    
    
    // configure MCSession handling
    _sessionController = [[MPISessionController alloc] init];
    self.sessionController.delegate = self;
    
    _audioManager = [[MPIAudioManager alloc] init];
    
    // setup self as motion manager delegate
    [MPIMotionManager instance].delegate = self;
}

+ (MPIGameManager *)instance
{
    static MPIGameManager* sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MPIGameManager alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark - Memory management

- (void)dealloc
{
    // Nil out delegates
    _sessionController.delegate = nil;
    
    _avSession = nil;
}

#pragma mark - Time sync
// initiates simple algorithm to calculate system time delta with specified player
- (void)calculateTimeDeltaFrom:(id)playerID
{
    // first clear latency array so that we can refresh values
    _timeLatencies = [[NSMutableArray alloc] init];
    // send first message to kick off the process
    _lastSendTimestamp = [[NSDate date] timeIntervalSince1970];
    [_sessionController sendTimestamp:[[NSNumber alloc] initWithDouble:_lastSendTimestamp] toPeer:playerID];
}
// returns the system time plus delta based on time sync process
- (NSDate*)currentTime
{
    return [NSDate dateWithTimeIntervalSinceNow:_timeDeltaSeconds];
}

- (BOOL)recievedTimestamp:(id)playerID value:(NSNumber *)val
{
    NSLog(@"%lu", (unsigned long)_timeLatencies.count);
    
    double localTimestamp = [[NSDate date] timeIntervalSince1970];
    double serverTimestamp = [val doubleValue];
    
    // calculate current iteration latency
    double latency = (localTimestamp - _lastSendTimestamp) / 2;
    [_timeLatencies addObject:[[NSNumber alloc] initWithDouble:latency]];
    
    
    // check how many latency calculations we have
    if (_timeLatencies.count >= kTimeSyncIterations) {
        // done with sync process ... calculate final offset
        double total;
        total = 0;
        for(NSNumber *value in _timeLatencies){
            total+=[value floatValue];
        }
        
        // average latencies
        double averageLatency = total / _timeLatencies.count;
        
        // save final offset
        _timeDeltaSeconds = serverTimestamp - localTimestamp + averageLatency;
        
        // save configuration to event logger
        [MPIEventLogger sharedInstance].timeDeltaSeconds = _timeDeltaSeconds;
        
        NSLog(@"TimeSync Complete. Delta: %f", _timeDeltaSeconds);
        
        // tell caller that we are done
        return YES;
        
    } else if (_timeLatencies.count == 1) {
        
        // save first iteration offset
        _timeDeltaSeconds = serverTimestamp - localTimestamp + latency;
        
    }
    
    // save last send with initially calculated offset
    _lastSendTimestamp = [[NSDate date] timeIntervalSince1970] + _timeDeltaSeconds;
    
    // send back to server
    [_sessionController sendTimestamp:[[NSNumber alloc] initWithDouble:_lastSendTimestamp] toPeer:_sessionController.timeServerPeerID];
    
    //NSLog(@"local: %f, server: %f, latency: %f, lastSend: %f",
    //      localTimestamp, serverTimestamp, latency, _lastSendTimestamp);
    
    return NO;
    
}

#pragma mark - MotionManagerDelegate protocol conformance

- (void)attitudeChanged:(float)yaw pitch:(float)pitch roll:(float)roll
{
    // log for now ...
    NSLog(@"yaw: %f, pitch: %f, roll: %f", yaw, pitch, roll);
    // TODO: send message to peers
}

- (void)rotationChanged:(float)x y:(float)y z:(float)z
{
    // log for now ...
    NSLog(@"x: %f, y: %f, z: %f", x, y, z);
    // TODO: send message to peers
    
    // TEST: use y value to change display
    //[self requestColorChange:_sessionController.connectedPeers[0] value:[[NSNumber alloc] initWithFloat:y]];
}

#pragma mark - SessionControllerDelegate protocol conformance

- (void)session:(MPISessionController *)session didChangeState:(MPILocalSessionState)state
{
    MPIDebug(@"LocalSession changed state: %ld", state);
}

- (void)peer:(MCPeerID *)peerID didChangeState:(MPIPeerState)state
{
    MPIDebug(@"Peer (%@) changed state: %ld", peerID.displayName, state);
    
    // then add to appropriate collection
    switch(state) {
        case MPIPeerStateConnected:
            [self.connectedPeers addObject:peerID];
            [self.connectingPeers removeObject:peerID];
            [self.disconnectedPeers removeObject:peerID];
            break;
        case MPIPeerStateDisconnected:
            [self.disconnectedPeers addObject:peerID];
            [self.connectingPeers removeObject:peerID];
            [self.connectedPeers removeObject:peerID];
            break;
        case MPIPeerStateDiscovered:
            [self.connectingPeers addObject:peerID];
            [self.connectedPeers removeObject:peerID];
            [self.disconnectedPeers removeObject:peerID];
            break;
        case MPIPeerStateInvited:
            [self.connectingPeers addObject:peerID];
            [self.connectedPeers removeObject:peerID];
            [self.disconnectedPeers removeObject:peerID];
            break;
        case MPIPeerStateInviteAccepted:
            [self.connectedPeers addObject:peerID];
            [self.connectingPeers removeObject:peerID];
            [self.disconnectedPeers removeObject:peerID];
            break;
        case MPIPeerStateInviteDeclined:
            [self.disconnectedPeers addObject:peerID];
            [self.connectingPeers removeObject:peerID];
            [self.connectedPeers removeObject:peerID];
            break;
        case MPIPeerStateSyncingTime:
            [self.connectingPeers addObject:peerID];
            [self.connectedPeers removeObject:peerID];
            [self.disconnectedPeers removeObject:peerID];
            break;
        case MPIPeerStateStale:
            [self.disconnectedPeers addObject:peerID];
            [self.connectingPeers removeObject:peerID];
            [self.connectedPeers removeObject:peerID];
            break;
    }
    
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyPlayersChange];
    });
}


- (void)session:(MPISessionController *)session didReceiveAudioStream:(NSInputStream *)stream
{
    [_audioManager playStream:stream];
}

- (void)session:(MPISessionController *)session didReceiveAudioFileStream:(NSInputStream *)stream
{
    [_audioManager playFileStream:stream];
}

- (void)session:(MPISessionController *)session didReceiveAudioFileFrom:(NSString*)playerName atPath:(NSString*)filePath
{
    // add as new audio loop ... but don't play until receiving command
    [_audioManager addAudioLoop:playerName forURL:[NSURL fileURLWithPath:filePath] andPlay:YES];
}



- (void)requestFlashChange:(id)peerID value:(NSNumber*)val {
    [_sessionController sendMessage:@"1" value:val toPeer:peerID];
}
- (void)requestSoundChange:(id)peerID value:(NSNumber*)val {
    [_sessionController sendMessage:@"2" value:val toPeer:peerID asReliable:NO];
}
- (void)requestColorChange:(id)peerID value:(NSNumber*)val {
    [_sessionController sendMessage:@"3" value:val toPeer:peerID asReliable:NO];
}
- (void)requestTimeSync:(id)peerID value:(NSNumber *)val {
    [_sessionController sendMessage:@"5" value:val toPeer:peerID];
}

- (void)handleActionRequest:(NSDictionary*)json type:(NSString*)type fromPeer:(id)fromPeerID {
    
    NSError *error = nil;
    if ([type isEqualToString:@"1"]) {
        
        MPIMessage *msg = [MTLJSONAdapter modelOfClass:[MPIMessage class] fromJSONDictionary:json error:&error];
        
        // change flash value
        [self toggleFlashlight];
        [_audioManager muteLoop:![msg.val boolValue] name:@"organ"];
        [_audioManager muteLoop:![msg.val boolValue] name:@"drums"];
        
        
    } else if ([type isEqualToString:@"2"]) {
        MPIMessage *msg = [MTLJSONAdapter modelOfClass:[MPIMessage class] fromJSONDictionary:json error:&error];
        // change sound of players
        self.volume = msg.val;
        //[self notifyVolumeChange];
        [_audioManager setLoopVolume:[msg.val floatValue] name:@"organ"];
        
        // set player loop volume
        // using local display name ... since file should be named based on recording from a different
        // device for my device
        //[_audioManager setLoopVolume:[msg.val floatValue] name:[_sessionController displayName]];
        
    } else if ([type isEqualToString:@"3"]) {
        MPIMessage *msg = [MTLJSONAdapter modelOfClass:[MPIMessage class] fromJSONDictionary:json error:&error];
        // change color of players
        self.color = msg.val;
        [self notifyColorChange];
        [_audioManager setLoopVolume:[msg.val floatValue] name:@"drums"];
        
        
        [_audioManager setLoopVolume:[msg.val floatValue]*1.5 name:[_sessionController displayName]];
        
    } else if ([type isEqualToString:@"4"]) {
        // timestamp handled by session controller
    } else if ([type isEqualToString:@"5"]) {
        // request for time sync handled by session controller
    } else if ([type isEqualToString:@"6"]) {
        
        MPISongInfoMessage *msg = [MTLJSONAdapter modelOfClass:[MPISongInfoMessage class] fromJSONDictionary:json error:&error];
        _lastSongMessage = msg;
        [self notifySongChange];
        
    } else if ([type isEqualToString:@"7"]) {
        
        MPIMessage *msg = [MTLJSONAdapter modelOfClass:[MPIMessage class] fromJSONDictionary:json error:&error];
        // start / stop play of recording
        [_audioManager muteLoop:![msg.val boolValue] name:[_sessionController displayName]];
        
    } else if ([type isEqualToString:@"8"]) {
        
        //MPIMessage *msg = [MTLJSONAdapter modelOfClass:[MPIMessage class] fromJSONDictionary:json error:&error];
        //NSLog(@"Received hearbeat from %@", msg.senderID);
        
        //
        // TODO: save heartbeat timestamp with peer state
        // AND: queue up response
        //
        
        if ([_connectingPeers containsObject:fromPeerID]) {
            // on receipt of first heartbeat ... we know the time sync is complete
            // notify that peer state is connected and ready to engage
            [_sessionController.delegate peer:fromPeerID didChangeState:MPIPeerStateConnected];
        } else if ([_disconnectedPeers containsObject:fromPeerID]) {
            MPIWarn(@"Heartbeat received from disconnected peer %@", fromPeerID);
        }
        
    }
}

- (void)toggleFlashlight
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (device.isTorchAvailable && device.torchMode == AVCaptureTorchModeOff)
    {
        // Create an AV session
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        
        // Create device input and add to current session
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error: nil];
        [session addInput:input];
        
        // Create video output and add to current session
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [session addOutput:output];
        
        // Start session configuration
        [session beginConfiguration];
        [device lockForConfiguration:nil];
        
        if([device isTorchModeSupported:AVCaptureTorchModeOn]){
            // Set torch to on
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        
        [device unlockForConfiguration];
        [session commitConfiguration];
        
        // Start the session
        [session startRunning];
        
        // Keep the session around
        _avSession = session;
        
        //[output release];
    }
    else
    {
        [_avSession stopRunning];
        _avSession = nil;
    }
}

- (void) notifyPlayersChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"playerListChanged" object:self];
}
- (void) notifyVolumeChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"volumeChanged" object:self];
}
- (void) notifyColorChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"colorChanged" object:self];
}
- (void) notifyAudioInChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"audioInChanged" object:self];
}
- (void) notifySongChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"songChanged" object:self];
}

- (void) startEcho:(NSOutputStream*)stream
{
    [_audioManager openMic:stream];
}
- (void) stopEcho
{
    [_audioManager closeMic];
}


- (void)startRecordMicFor:(NSString*)playerName {
    [_audioManager startRecordingToFile:[_audioManager recordingFilePathFor:playerName]];
}
- (void)stopRecordMicFor:(NSString*)playerName withPeer:(id)peerID {
    NSString* filePath = [_audioManager recordingFilePathFor:playerName];
    // tell audio manager to stop recording
    [_audioManager stopRecordingToFile:filePath];
    
    // send when file is done recording
    [_sessionController sendAudioFileAtPath:filePath toPeer:peerID];
    
    // auto-play there
    // NOTE: do this as part of file recieve ... since we need to wait for file transfer
    //[self startPlayRecordingFor:playerName onPeer:peerID];
    
    // auto-play here
    [self startPlayRecordingFor:playerName];
}

- (void)startPlayRecordingFor:(NSString*)playerID {
    NSString *filePath = [_audioManager recordingFilePathFor:playerID];
    [_audioManager startPlayingFromFile:filePath];
}

- (void)startStreamingRecordingTo:(id)peerID fromPlayerName:(NSString*)playerName {
    
    //[_sessionController sendAudioFileAtPath:[self recordingFilePathFor:playerName] toPeer:peerID];
    
    //
    // TODO: send message to start playing transfered audio
    //
    
    //NSOutputStream *stream = [_sessionController outputStreamForPeer:peerID withName:@"audio-file"];
    //[_audioManager startAudioFileStream:stream fromPath:[self recordingFilePathFor:playerName]];
}

- (void)stopStreamingRecordingFrom:(NSString*)playerName {
    [_audioManager stopAudioFileStreamFrom:[_audioManager recordingFilePathFor:playerName]];
}

- (void)stopPlayRecordingFor:(NSString *)playerID {
    [_audioManager stopPlayingFromFile];
}


- (void)startPlayRecordingFor:(NSString *)playerID onPeer:peerID {
    // send play command
    [_sessionController sendMessage:@"7" value:[[NSNumber alloc] initWithInt:1] toPeer:peerID];
}
- (void)stopPlayRecordingFor:(NSString *)playerID onPeer:peerID {
    // send stop command
    [_sessionController sendMessage:@"7" value:[[NSNumber alloc] initWithInt:0] toPeer:peerID];
}

- (void) changeReverb:(BOOL)on
{
    [_audioManager enableReverb:on];
}
- (void) changeLimiter:(BOOL)on
{
    [_audioManager enableLimiter:on];
}
- (void) changeExpander:(BOOL)on
{
    [_audioManager enableExpander:on];
}
- (void) changeRecordingGain:(float)val
{
    _audioManager.recordingGain = val;
}

- (void) startup
{
    [_sessionController startup];
    //[[MPIMotionManager instance] start];
    
    // try to send heartbeat to all connected peers
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:kHearbeatIntervalSeconds target:self
                                                     selector:@selector(broadcastHeartbeat:) userInfo:nil repeats:YES];
}
- (void) shutdown
{
    [_sessionController shutdown];
    [_avSession stopRunning];
    _avSession = nil;
    [[MPIMotionManager instance] stop];
    
    
    [self.connectingPeers removeAllObjects];
    [self.connectedPeers removeAllObjects];
    [self.disconnectedPeers removeAllObjects];
}

// every kHeartbeatIntervalSeconds ... to all peers
- (void) broadcastHeartbeat:(NSTimer *)incomingTimer
{
    double timestamp = [[NSDate date] timeIntervalSince1970];
    // NOTE: sending to each individually ... to enable better understanding of connection status via send msg error
    for (int i = 0; i < _connectedPeers.count; i++) {
        MCPeerID* peerID = _connectedPeers[i];
        [_sessionController sendMessage:@"8" value:[[NSNumber alloc] initWithDouble:timestamp] toPeer:peerID asReliable:NO];
    }
}

// one time ... on sync complete
- (void) startHeartbeatWithPeer:(id)peerID
{
    double timestamp = [[NSDate date] timeIntervalSince1970];
    [_sessionController sendMessage:@"8" value:[[NSNumber alloc] initWithDouble:timestamp] toPeer:peerID asReliable:NO];
    
    //
    // TODO: expect response ??
    // NO: ... for now we are just sending without expectation
    //
    
}

@end
