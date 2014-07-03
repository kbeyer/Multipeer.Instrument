//
//  MPIInputStreamChannel.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/2/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIInputStreamChannel.h"
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "AEAudioController+Audiobus.h"
#import "AEAudioController+AudiobusStub.h"

#import "TDAudioInputStreamer.h"

static const int kAudioBufferLength = 16384;

@interface MPIInputStreamChannel () {
    TPCircularBuffer _buffer;
    TDAudioInputStreamer* _streamer;
    BOOL _audiobusConnectedToSelf;
}
@property (nonatomic, strong) AEAudioController *audioController;
@end

@implementation MPIInputStreamChannel
@synthesize audioController=_audioController, volume = _volume;

+(NSSet *)keyPathsForValuesAffectingAudioDescription {
    return [NSSet setWithObject:@"audioController.inputAudioDescription"];
}

- (id)initWithAudioController:(AEAudioController*)audioController stream:(NSInputStream*)stream {
    if ( !(self = [super init]) ) return nil;
    TPCircularBufferInit(&_buffer, kAudioBufferLength);
    self.audioController = audioController;
    _volume = 1.0;
    //_inputStream = stream;
    _streamer = [[TDAudioInputStreamer alloc] initWithInputStream:stream buffer:_buffer audioController:audioController];
    return self;
}

- (void)dealloc {
    TPCircularBufferCleanup(&_buffer);
    self.audioController = nil;
    [self stop];
}


static OSStatus renderCallback(__unsafe_unretained MPIInputStreamChannel *THIS,
                               __unsafe_unretained AEAudioController *audioController,
                               const AudioTimeStamp     *time,
                               UInt32                    frames,
                               AudioBufferList          *audio) {
    while ( 1 ) {
        // Discard any buffers with an incompatible format, in the event of a format change
        AudioBufferList *nextBuffer = TPCircularBufferNextBufferList(&THIS->_buffer, NULL);
        if ( !nextBuffer ) break;
        if ( nextBuffer->mNumberBuffers == audio->mNumberBuffers ) break;
        TPCircularBufferConsumeNextBufferList(&THIS->_buffer);
    }
    
    UInt32 fillCount = TPCircularBufferPeek(&THIS->_buffer, NULL, AEAudioControllerAudioDescription(audioController));
    if ( fillCount > frames ) {
        UInt32 skip = fillCount - frames;
        TPCircularBufferDequeueBufferListFrames(&THIS->_buffer,
                                                &skip,
                                                NULL,
                                                NULL,
                                                AEAudioControllerAudioDescription(audioController));
    }
    
    TPCircularBufferDequeueBufferListFrames(&THIS->_buffer,
                                            &frames,
                                            audio,
                                            NULL,
                                            AEAudioControllerAudioDescription(audioController));
    
    NSLog(@"renderCallback %i", fillCount);
    
    return noErr;
}

-(AEAudioControllerRenderCallback)renderCallback {
    return renderCallback;
}

-(AudioStreamBasicDescription)audioDescription {
    return _audioController.inputAudioDescription;
}



- (void)start
{
    [_streamer start];
}
- (void)stop
{
    [_streamer stop];
}


@end


