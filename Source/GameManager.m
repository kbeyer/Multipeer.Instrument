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
@end


static int const kTimeSyncIterations = 10;

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
    // configure MCSession handling
    _sessionController = [[MPISessionController alloc] init];
    self.sessionController.delegate = self;
    
    _audioManager = [[MPIAudioManager alloc] init];
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

- (void)recievedTimestamp:(id)playerID value:(NSNumber *)val
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
        return;
        
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
    
}

#pragma mark - SessionControllerDelegate protocol conformance

- (void)sessionDidChangeState
{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyPlayersChange];
    });
}

- (void)session:(MPISessionController *)session didReceiveAudioStream:(NSInputStream *)stream
{
    if (!self.audioInStream) {
        self.audioInStream = [[TDAudioInputStreamer alloc] initWithInputStream:stream];
        [self notifyAudioInChange];
    }
}


- (void)requestFlashChange:(id)peerID value:(NSNumber*)val {
    [_sessionController sendMessage:@"1" value:val toPeer:peerID];
}
- (void)requestSoundChange:(id)peerID value:(NSNumber*)val {
    [_sessionController sendMessage:@"2" value:val toPeer:peerID];
}
- (void)requestColorChange:(id)peerID value:(NSNumber*)val {
    [_sessionController sendMessage:@"3" value:val toPeer:peerID];
}
- (void)requestTimeSync:(id)peerID value:(NSNumber *)val {
    [_sessionController sendMessage:@"5" value:val toPeer:peerID];
}

- (void)handleActionRequest:(id)msg type:(NSString*)type value:(NSNumber*)val {
    
    if ([type isEqualToString:@"1"]) {
        // change flash value
        [self toggleFlashlight];
        [_audioManager muteLoop:![val boolValue] name:@"organ"];
        [_audioManager muteLoop:![val boolValue] name:@"drums"];
    } else if ([type isEqualToString:@"2"]) {
        // change sound of players
        self.volume = val;
        //[self notifyVolumeChange];
        [_audioManager setLoopVolume:[val floatValue] name:@"organ"];
    } else if ([type isEqualToString:@"3"]) {
        // change color of players
        self.color = val;
        [self notifyColorChange];
        [_audioManager setLoopVolume:[val floatValue] name:@"drums"];
    } else if ([type isEqualToString:@"4"]) {
        // timestamp handled by session controller
    } else if ([type isEqualToString:@"5"]) {
        // request for time sync handled by session controller
    } else if ([type isEqualToString:@"6"]) {
        _lastSongMessage = msg;
        [self notifySongChange];
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
- (void) startup
{
    [_sessionController startup];
}
- (void) shutdown
{
    [_sessionController shutdown];
}

@end
