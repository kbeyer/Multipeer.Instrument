//
//  TDAudioInputStreamer.m
//  TDAudioStreamer
//
//  Created by Tony DiPasquale on 10/4/13.
//  Copyright (c) 2013 Tony DiPasquale. The MIT License (MIT).
//

#import "TDAudioInputStreamer.h"
#import "TDAudioFileStream.h"
#import "TDAudioStream.h"
#import "TDAudioQueue.h"
#import "TDAudioQueueBuffer.h"
#import "TDAudioQueueFiller.h"
#import "TDAudioStreamerConstants.h"


static const int kIncrementalLoadBufferSize = 4096;
static const int kMaxAudioFileReadSize = 16384;

@interface TDAudioInputStreamer () <TDAudioStreamDelegate, TDAudioFileStreamDelegate, TDAudioQueueDelegate>
{
    AEAudioController *_audioController;
}

@property (strong, nonatomic) NSThread *audioStreamerThread;
@property (assign, atomic) BOOL isPlaying;

@property (strong, nonatomic) TDAudioStream *audioStream;
@property (strong, nonatomic) TDAudioFileStream *audioFileStream;
@property (strong, nonatomic) TDAudioQueue *audioQueue;


@end

@implementation TDAudioInputStreamer

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    self.audioFileStream = [[TDAudioFileStream alloc] init];
    if (!self.audioFileStream) return nil;

    self.audioFileStream.delegate = self;

    return self;
}

- (instancetype)initWithInputStream:(NSInputStream *)inputStream audioController:(AEAudioController *)audioController
{
    self = [self init];
    if (!self) return nil;

    _audioController = audioController;
    
    self.audioStream = [[TDAudioStream alloc] initWithInputStream:inputStream];
    if (!self.audioStream) return nil;

    self.audioStream.delegate = self;
    
    /*
    AudioStreamBasicDescription audioDescription = _audioController.inputAudioDescription;
    
    // Prepare buffers
    int bufferCount = (audioDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? audioDescription.mChannelsPerFrame : 1;
    int channelsPerBuffer = (audioDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? 1 : audioDescription.mChannelsPerFrame;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(audioDescription, _audioReceiverBlock ? kIncrementalLoadBufferSize : (UInt32)fileLengthInFrames);
    
    
    
    AudioBufferList *scratchBufferList = AEAllocateAndInitAudioBufferList(audioDescription, 0);
    */
    
    
    

    return self;
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
        [self.audioStream open];

        self.isPlaying = YES;

        while (self.isPlaying && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    }
}

- (void)parseData:(const void *)data length:(UInt32)length;
{
    OSStatus status;
    
    
    // Get stream data format
    AudioStreamBasicDescription streamAudioDescription = _audioController.audioDescription;
    
    
    // Prepare buffers
    int bufferCount = (streamAudioDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? streamAudioDescription.mChannelsPerFrame : 1;
    int channelsPerBuffer = (streamAudioDescription.mFormatFlags & kAudioFormatFlagIsNonInterleaved) ? 1 : streamAudioDescription.mChannelsPerFrame;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(streamAudioDescription, kIncrementalLoadBufferSize);

    
    AudioBufferList *scratchBufferList = AEAllocateAndInitAudioBufferList(streamAudioDescription, 0);
    
    // Perform read in multiple small chunks (otherwise ExtAudioFileRead crashes when performing sample rate conversion)
    UInt64 readFrames = 0;
    
            for ( int i=0; i<scratchBufferList->mNumberBuffers; i++ ) {
                scratchBufferList->mBuffers[i].mNumberChannels = channelsPerBuffer;
                scratchBufferList->mBuffers[i].mData = (char*)bufferList->mBuffers[i].mData + readFrames*streamAudioDescription.mBytesPerFrame;
                scratchBufferList->mBuffers[i].mDataByteSize = kMaxAudioFileReadSize;
            }
        
        // Perform read
        UInt32 numberOfPackets = (UInt32)(scratchBufferList->mBuffers[0].mDataByteSize / streamAudioDescription.mBytesPerFrame);
    
        status = ExtAudioFileRead(audioFile, &numberOfPackets, scratchBufferList);
    
}

#pragma mark - Properties

- (UInt32)audioStreamReadMaxLength
{
    if (!_audioStreamReadMaxLength)
        _audioStreamReadMaxLength = kTDAudioStreamReadMaxLength;

    return _audioStreamReadMaxLength;
}

- (UInt32)audioQueueBufferSize
{
    if (!_audioQueueBufferSize)
        _audioQueueBufferSize = kTDAudioQueueBufferSize;

    return _audioQueueBufferSize;
}

- (UInt32)audioQueueBufferCount
{
    if (!_audioQueueBufferCount)
        _audioQueueBufferCount = kTDAudioQueueBufferCount;

    return _audioQueueBufferCount;
}

#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    switch (event) {
        case TDAudioStreamEventHasData: {
            uint8_t bytes[self.audioStreamReadMaxLength];
            UInt32 length = [audioStream readData:bytes maxLength:self.audioStreamReadMaxLength];
            
            //[self.audioFileStream parseData:bytes length:length];
            
            [self parseData:bytes length:length];
            //
            // TODO : write to AudioPlayer buffer
            //
            
            NSLog(@"audio in has data %i", (unsigned int)length);
            
            break;
        }

        case TDAudioStreamEventEnd:
            self.isPlaying = NO;
            [self.audioQueue finish];
            break;

        case TDAudioStreamEventError:
            [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioStreamDidFinishPlayingNotification object:nil];
            break;

        default:
            break;
    }
}

#pragma mark - TDAudioFileStreamDelegate

- (void)audioFileStreamDidBecomeReady:(TDAudioFileStream *)audioFileStream
{
    UInt32 bufferSize = audioFileStream.packetBufferSize ? audioFileStream.packetBufferSize : self.audioQueueBufferSize;

    self.audioQueue = [[TDAudioQueue alloc] initWithBasicDescription:audioFileStream.basicDescription bufferCount:self.audioQueueBufferCount bufferSize:bufferSize magicCookieData:audioFileStream.magicCookieData magicCookieSize:audioFileStream.magicCookieLength];

    self.audioQueue.delegate = self;
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveError:(OSStatus)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TDAudioStreamDidFinishPlayingNotification object:nil];
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length
{
    NSLog(@"audio in length %i", (unsigned int)length);
    
    [TDAudioQueueFiller fillAudioQueue:self.audioQueue withData:data length:length offset:0];
}

- (void)audioFileStream:(TDAudioFileStream *)audioFileStream didReceiveData:(const void *)data length:(UInt32)length packetDescription:(AudioStreamPacketDescription)packetDescription
{
    
    NSLog(@"received data %i", (unsigned int)length);
    
    [TDAudioQueueFiller fillAudioQueue:self.audioQueue withData:data length:length packetDescription:packetDescription];
}

#pragma mark - TDAudioQueueDelegate

- (void)audioQueueDidFinishPlaying:(TDAudioQueue *)audioQueue
{
    [self performSelectorOnMainThread:@selector(notifyMainThread:) withObject:TDAudioStreamDidFinishPlayingNotification waitUntilDone:NO];
}

- (void)audioQueueDidStartPlaying:(TDAudioQueue *)audioQueue
{
    [self performSelectorOnMainThread:@selector(notifyMainThread:) withObject:TDAudioStreamDidStartPlayingNotification waitUntilDone:NO];
}

- (void)notifyMainThread:(NSString *)notificationName
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

#pragma mark - Public Methods

- (void)resume
{
    [self.audioQueue play];
}

- (void)pause
{
    [self.audioQueue pause];
}

- (void)stop
{
    [self performSelector:@selector(stopThread) onThread:self.audioStreamerThread withObject:nil waitUntilDone:YES];
}

- (void)stopThread
{
    self.isPlaying = NO;
    [self.audioQueue stop];
}

@end
