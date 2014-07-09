//
//  TDAudioInputStreamer.h
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

#import "AEAudioController.h"

@interface TDAudioInputStreamer : NSObject

@property (assign, nonatomic) UInt32 audioStreamReadMaxLength;
@property (assign, nonatomic) UInt32 audioQueueBufferSize;
@property (assign, nonatomic) UInt32 audioQueueBufferCount;

@property (assign, nonatomic) AudioBufferList *bufferList;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream audioController:(AEAudioController*)audioController streamChannel:(id)streamChannel;



- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;

@end
