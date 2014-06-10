//
//  MPIGame.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "Game.h"
#import "ActionMessage.h"
#import <AVFoundation/AVFoundation.h>

@interface MPIGame()
@property AVCaptureSession* avSession;
@end

@implementation MPIGame

@synthesize volume, color;

- (BOOL) isValid {
    if (_uuid) {
        return YES;
    }
    return NO;
}

- (void)requestFlashChange:(NSString *)playerUUID value:(float)val {
    
    //Start an activity indicator here
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //Call your function or whatever work that needs to be done
        //Code in this part is run on a background thread
        MPIActionMessage *action = [[MPIActionMessage alloc] init];
        action.to_uuid = playerUUID;
        action.actionname = @"flash";
        action.actionvalue = val;
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            //Stop your activity indicator or anything else with the GUI
            //Code here is run on the main thread
            NSLog(@"Done with background action request");
        });
    });

}
- (void)requestSoundChange:(NSString *)playerUUID value:(float)val {
    MPIActionMessage *action = [[MPIActionMessage alloc] init];
    action.to_uuid = playerUUID;
    action.actionname = @"sound";
    action.actionvalue = val;
}

- (void)requestColorChange:(NSString *)playerUUID value:(float)val {
    MPIActionMessage *action = [[MPIActionMessage alloc] init];
    action.to_uuid = playerUUID;
    action.actionname = @"color";
    action.actionvalue = val;
}

- (void)handleActionRequest:(MPIActionMessage *)action {
    
    // check if this action is for me
    if(![action.to_uuid isEqualToString:[self uuid]]) {
        return;
    }
    
    if ([action.actionname isEqualToString:@"flash"]) {
        // change flash value
        [self toggleFlashlight];
    } else if ([action.actionname isEqualToString:@"sound"]) {
        // change sound of players
        self.volume = action.actionvalue;
        [self notifyVolumeChange];
    } else if ([action.actionname isEqualToString:@"color"]) {
        // change color of players
        self.color = action.actionvalue;
        [self notifyColorChange];
    }
}

- (void)toggleFlashlight
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (device.torchMode == AVCaptureTorchModeOff)
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
        
        // Set torch to on
        [device setTorchMode:AVCaptureTorchModeOn];
        
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

- (void)handleJoinRequest:(MPIJoinRequest *)request
{
    // ignore request from game owner
    if ([request.from_uuid isEqualToString:_uuid]) {
        return;
    }
    
    // convert request to player
    MPIPlayer* player = [[MPIPlayer alloc] init];
    player.uuid = request.from_uuid;
    player.name = request.from_name;
    player.lastActive = [NSDate new];
    
    // auto-add players for now
    [self addUpdatePlayer: player];
}

- (void) addUpdatePlayer: (MPIPlayer *)player {
    
    // check if new or existing
    int existingIndex = -1;
    for (int i = 0; i < _players.count; i++) {
        MPIPlayer* currentPlayer = _players[i];
        if (currentPlayer.uuid == player.uuid) {
            existingIndex = i;
            break;
        }
    }
    
    if (existingIndex == -1) {
        [_players addObject:player];
        
        // refresh table when players are added
        [self notifyPlayersChange];
    }
}

- (void) removePlayer: (NSString *)uuid {
    // find player
    int existingIndex = -1;
    for (int i = 0; i < _players.count; i++) {
        MPIPlayer* player = _players[i];
        if (player.uuid == uuid) {
            existingIndex = i;
            break;
        }
    }
    
    if (existingIndex >= 0) {
        [_players removeObjectAtIndex:existingIndex];
        
        // refresh table when players are removed
        [self notifyPlayersChange];
    }
    
}

- (void) notifyPlayersChange {
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"playerListChanged" object:self];
}
- (void) notifyVolumeChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"volumeChanged" object:self];
}
- (void) notifyColorChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"colorChanged" object:self];
}

@end
