//
//  MPIAudioManager.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AEAudioController;
@class AEAudioFilePlayer;

@interface MPIAudioManager : NSObject

@property (retain, nonatomic) AEAudioController *audioController;

@property (readwrite) float recordingGain;

-(void)muteLoop:(BOOL)mute name:(NSString*)key;
-(void)setLoopVolume:(float)volume name:(NSString*)key;

// enable addition of audio loops
-(AEAudioFilePlayer*)addAudioLoop:(NSString*)key forURL:(NSURL*)fileUrl;
-(void)addAudioLoop:(NSString*)key forURL:(NSURL *)fileUrl andPlay:(BOOL)autoPlay;

// listen to mic and stream to peer(s)
-(void)openMic:(NSOutputStream*)stream;
// top listening to and streaming mic
-(void)closeMic;

// play mic stream
-(void)playStream:(NSInputStream*)stream;
// play file stream
-(void)playFileStream:(NSInputStream*)stream;

// stream audio file to output stream
-(void)startAudioFileStream:(NSOutputStream*)stream fromPath:(NSString*)filePath;
-(void)stopAudioFileStreamFrom:(NSString*)filePath;

// start recording to a file
-(void)startRecordingToFile:(NSString*)filePath;
-(void)stopRecordingToFile:(NSString*)filePath;

- (NSString*)recordingFilePathFor:(NSString*)playerID;

-(void)enableReverb:(BOOL)on;
-(void)enableLimiter:(BOOL)on;
-(void)enableExpander:(BOOL)on;

// start playing from file
-(void)startPlayingFromFile:(NSString*)filePath;
-(void)stopPlayingFromFile;

@end
