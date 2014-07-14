//
//  MPIAudioStreamer.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/3/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIAudioStreamer.h"
#import "AEMixerBuffer.h"
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"

#define kProcessChunkSize 8192

NSString * MPIStreamerDidEncounterErrorNotification = @"MPIStreamerDidEncounterErrorNotification";
NSString * kMPIStreamerErrorKey = @"error";

@interface MPIAudioStreamer () {
    BOOL _streaming;
    AudioBufferList *_buffer;
    AEAudioController *_audioController;
    NSOutputStream *_outputStream;
    TPCircularBuffer _circularBuffer;
}
@property (nonatomic, strong) AEMixerBuffer *mixer;
@end

@implementation MPIAudioStreamer
@synthesize mixer = _mixer, currentTime = _currentTime;

+ (BOOL)AACEncodingAvailable {
    return [AEAudioFileWriter AACEncodingAvailable];
}

- (id)initWithAudioController:(AEAudioController*)audioController {
    if ( !(self = [super init]) ) return nil;
    _audioController = audioController;
    self.mixer = [[AEMixerBuffer alloc] initWithClientFormat:audioController.audioDescription];
    
    if ( audioController.audioInputAvailable && audioController.inputAudioDescription.mChannelsPerFrame != audioController.audioDescription.mChannelsPerFrame ) {
        [_mixer setAudioDescription:*AEAudioControllerInputAudioDescription(audioController) forSource:AEAudioSourceInput];
    }
    _buffer = AEAllocateAndInitAudioBufferList(audioController.audioDescription, 0);
    
    return self;
}

-(void)dealloc {
    free(_buffer);
}


#pragma mark - network thread


+ (NSThread *)networkThread {
    static NSThread *networkThread = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        networkThread =
        [[NSThread alloc] initWithTarget:self
                                selector:@selector(networkThreadMain:)
                                  object:nil];
        [networkThread start];
    });
    
    return networkThread;
}

+ (void)networkThreadMain:(id)unused {
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] run];
        }
    } while (YES);
}

- (void)scheduleInCurrentThread
{
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSRunLoopCommonModes];
}
- (void)unscheduleInCurrentThread
{
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSRunLoopCommonModes];
}


-(void)beginStreaming:(NSOutputStream *)stream {
    _outputStream = stream;
    _outputStream.delegate = self;
    [self performSelector:@selector(scheduleInCurrentThread)
                 onThread:[[self class] networkThread]
               withObject:nil
            waitUntilDone:YES];
    [_outputStream open];
    
    _streaming = YES;
}

- (void)finishStreaming {
    _streaming = NO;
    
    [_outputStream close];
    _outputStream.delegate = nil;
    [self performSelector:@selector(unscheduleInCurrentThread)
                 onThread:[[self class] networkThread]
               withObject:nil
            waitUntilDone:YES];
}

static void audioCallback(__unsafe_unretained MPIAudioStreamer *THIS,
                          __unsafe_unretained AEAudioController *audioController,
                          void                     *source,
                          const AudioTimeStamp     *time,
                          UInt32                    frames,
                          AudioBufferList          *audio) {
    if ( !THIS->_streaming ) return;
    
    
    // add to mixer
    AEMixerBufferEnqueue(THIS->_mixer, source, audio, frames, time);
    
    // Let the mixer buffer provide the audio buffer
    for ( int i=0; i<THIS->_buffer->mNumberBuffers; i++ ) {
        THIS->_buffer->mBuffers[i].mData = NULL;
        THIS->_buffer->mBuffers[i].mDataByteSize = 0;
    }
    
    THIS->_currentTime += AEConvertFramesToSeconds(audioController, frames);
 
    
    UInt32 bufferLength = kProcessChunkSize;
    AEMixerBufferDequeue(THIS->_mixer, THIS->_buffer, &bufferLength, NULL);
    
    if ( bufferLength > 0 ) {
        
        // copy all available data to audio buffer for streaming
        TPCircularBufferCopyAudioBufferList(&THIS->_circularBuffer, THIS->_buffer, time, kTPCircularBufferCopyAll, NULL);

    }
    
}

-(AEAudioControllerAudioCallback)receiverCallback {
    return audioCallback;
}


#pragma mark - NSStream delegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (!_streaming){ return; }
    
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            NSLog(@"AudioOutputStreamer Bytes Available");
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"AudioOutputStreamer Space Available");
            [self sendNext];
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"AudioOutputStreamer NSStreamEventEndEncountered");
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"AudioOutputStreamer NSStreamEventErrorOccurred");
            [self finishStreaming];
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"AudioOutputStreamer NSStreamEventOpenCompleted");
            break;
        case NSStreamEventNone:
            NSLog(@"AudioOutputStreamer NSStreamEventNone");
            break;
    }
}

- (void)sendNext
{
    while ( 1 ) {
        // Discard any buffers with an incompatible format, in the event of a format change
        AudioBufferList *nextBuffer = TPCircularBufferNextBufferList(&_circularBuffer, NULL);
        if ( !nextBuffer ) break;
        if ( nextBuffer->mNumberBuffers ==  _audioController.audioDescription.mChannelsPerFrame) break;
        TPCircularBufferConsumeNextBufferList(&_circularBuffer);
    }
    
    // setup audio buffers to copy data from stream into
    UInt32 frames = 512;
    
    AudioBuffer outBuffer;
    outBuffer.mNumberChannels = 1;
    outBuffer.mDataByteSize = frames * 2;
    outBuffer.mData = malloc( frames * 2 );
    
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0] = outBuffer;
    
    
    UInt32 fillCount = TPCircularBufferPeek(&_circularBuffer, NULL, AEAudioControllerAudioDescription(_audioController));
    if ( fillCount > frames ) {
        
        
        //
        // TODO: what if we don't throw these away?
        //
        
        UInt32 skip = fillCount - frames;
        TPCircularBufferDequeueBufferListFrames(&_circularBuffer,
                                                &skip,
                                                NULL,
                                                NULL,
                                                AEAudioControllerAudioDescription(_audioController));
        
        NSLog(@"fillCount (%i) > frames (%i)", fillCount, frames);
    }
    
    // if there is no data ... play oscillator
    if (YES || fillCount == 0) {
        
        NSLog(@"no mic data ... sending oscillator");
        
        __block float oscillatorPosition = 0;
        __block float oscillatorRate = 622.0/44100.0;
        for ( int i=0; i<frames; i++ ) {
            // Quick sin-esque oscillator
            float x = oscillatorPosition;
            x *= x; x -= 1.0; x *= x;       // x now in the range 0...1
            x *= INT16_MAX;
            x -= INT16_MAX / 2;
            oscillatorPosition += oscillatorRate;
            if ( oscillatorPosition > 1.0 ) oscillatorPosition -= 2.0;
            
            for (NSUInteger b = 0; b < outBufferList.mNumberBuffers; b++) {
                ((SInt16*)outBufferList.mBuffers[b].mData)[i] = x;
                //((SInt16*)outBufferList.mBuffers[1].mData)[i] = x;
            }
        }
    } else {
    
        // default case is to pull data queued from mic input
        TPCircularBufferDequeueBufferListFrames(&_circularBuffer,
                                            &frames,
                                            _buffer,
                                            NULL,
                                            AEAudioControllerAudioDescription(_audioController));
    }
    
    
    for (NSUInteger i = 0; i < outBufferList.mNumberBuffers; i++) {
        AudioBuffer audioBuffer = outBufferList.mBuffers[i];
        [_outputStream write:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
        NSLog(@"stream write buf: %lu size: %u", (unsigned long)i, (unsigned int)audioBuffer.mDataByteSize);
    }
    
    // free up temporary audio buffer after copy
    free(outBufferList.mBuffers[0].mData);
}

@end
