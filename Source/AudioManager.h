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

// listen to mic and stream to peer(s)
-(void)openMic:(NSOutputStream*)stream;
// top listening to and streaming mic
-(void)closeMic;

// play mic stream
-(void)playStream:(NSInputStream*)stream;


// start recording to a file
-(void)startRecordingToFile:(NSString*)filePath;
-(void)stopRecordingToFile;

// start playing from file
-(void)startPlayingFromFile:(NSString*)filePath;
-(void)stopPlayingFromFile;

@end
