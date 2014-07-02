//
//  TDAudioInputStreamer.h
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import <Foundation/Foundation.h>

#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"

@interface TDAudioInputStreamer : NSObject

@property (assign, nonatomic) UInt32 audioStreamReadMaxLength;
@property (assign, nonatomic) UInt32 audioQueueBufferSize;
@property (assign, nonatomic) UInt32 audioQueueBufferCount;

- (instancetype)initWithInputStream:(NSInputStream *)inputStream buffer:(TPCircularBuffer)buffer;

- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;

@end
