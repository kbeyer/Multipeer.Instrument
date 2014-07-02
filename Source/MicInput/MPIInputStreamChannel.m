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

static const int kAudioBufferLength = 16384;
static const int kAudiobusReceiverPortConnectedToSelfChanged;

UInt32 const kAudioStreamReadMaxLength = 512;

@interface MPIInputStreamChannel () <NSStreamDelegate> {
    TPCircularBuffer _buffer;
    NSInputStream *_inputStream;
    BOOL _audiobusConnectedToSelf;
}
@property (nonatomic, strong) AEAudioController *audioController;
@property (strong, nonatomic) NSThread *audioStreamerThread;
@property (assign, atomic) BOOL isPlaying;
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
    _inputStream = stream;
    return self;
}

- (void)dealloc {
    TPCircularBufferCleanup(&_buffer);
    self.audioController = nil;
    
    if (_inputStream) [self close];
}


- (void)start
{
    if (![[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        return [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    }
    
    self.audioStreamerThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [self.audioStreamerThread start];
    NSLog(@"Audio Streamer thread started");
}

- (void)run
{
    @autoreleasepool {
        [_inputStream open];
        
        self.isPlaying = YES;
        
        while (self.isPlaying && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    }
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
    
    return noErr;
}

-(AEAudioControllerRenderCallback)renderCallback {
    return renderCallback;
}

-(AudioStreamBasicDescription)audioDescription {
    return _audioController.inputAudioDescription;
}

#pragma mark - stream methods

- (void)open
{
    _inputStream.delegate = self;
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    return [_inputStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            
            self.isPlaying = YES;
            
            uint8_t bytes[kAudioStreamReadMaxLength];
            UInt32 length = [_inputStream read:bytes maxLength:kAudioStreamReadMaxLength];
            
            NSLog(@"audio in has data %i", (unsigned int)length);
            
            //
            // TODO: push data into circular buffer
            //
            TPCircularBufferProduceBytes(&(_buffer), bytes, kAudioStreamReadMaxLength);
            
            break;
            
        case NSStreamEventEndEncountered:
            self.isPlaying = NO;
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred");
            break;
            
        default:
            break;
    }
}

- (void)close
{
    [_inputStream close];
    _inputStream.delegate = nil;
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

#pragma mark - Public Methods

- (void)stop
{
    [self performSelector:@selector(stopThread) onThread:self.audioStreamerThread withObject:nil waitUntilDone:YES];
}

- (void)stopThread
{
    self.isPlaying = NO;
}

@end


