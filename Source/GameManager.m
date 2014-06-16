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
@end

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

#pragma mark - SessionControllerDelegate protocol conformance

- (void)sessionDidChangeState
{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self notifyPlayersChange];
    });
    
    // log session state change event
    //MPIActionMessage* msg = [[MPIActionMessage alloc] init];
    //msg.type = @"session change";
    
    // log to server
    //[[MPIEventLogger instance] log:kLogSource description:(MPIMessage*)msg];
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

- (void)handleActionRequest:(NSString*)type value:(NSNumber*)val {
    
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

@end
