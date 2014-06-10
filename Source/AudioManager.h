//
//  MPIAudioManager.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AEAudioController;

@interface MPIAudioManager : NSObject

@property (retain, nonatomic) AEAudioController *audioController;
-(void)muteLoop:(BOOL)mute name:(NSString*)key;
-(void)setLoopVolume:(float)volume name:(NSString*)key;


@end
