//
//  TDAudioOutputStreamer.h
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 11/14/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

@import MediaPlayer;
#import <Foundation/Foundation.h>

@class AVURLAsset;

@interface TDAudioOutputStreamer : NSObject

- (instancetype)initWithOutputStream:(NSOutputStream *)stream;

- (void)streamAudioFromSong:(MPMediaItem *)song;
- (void)streamAudioFromURL:(NSURL *)url;
- (void)start;
- (void)stop;


- (UInt32)writeData:(uint8_t *)data maxLength:(UInt32)maxLength;

@end
