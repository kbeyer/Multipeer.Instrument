//
//  MPIOutputStreamChannel.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/3/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIAudioStreamer.h"
#import "AEMixerBuffer.h"
#import "TDAudioStream.h"

#define kProcessChunkSize 8192

NSString * MPIStreamerDidEncounterErrorNotification = @"MPIStreamerDidEncounterErrorNotification";
NSString * kMPIStreamerErrorKey = @"error";

@interface MPIAudioStreamer ()  <TDAudioStreamDelegate> {
    BOOL _streaming;
    AudioBufferList *_buffer;
    AEAudioController *_audioController;
}
@property (nonatomic, strong) AEMixerBuffer *mixer;
@property (nonatomic, strong) TDAudioStream *audioStream;
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

-(void)beginStreaming:(NSOutputStream *)stream {
    _currentTime = 0.0;
    
    self.audioStream = [[TDAudioStream alloc] initWithOutputStream:stream];
    self.audioStream.delegate = self;
    
    [_audioStream open];
    
    _streaming = YES;
}

- (void)finishStreaming {
    _streaming = NO;
    [self.audioStream close];
}

struct reportError_t { void *THIS; OSStatus result; };
static void reportError(AEAudioController *audioController, void *userInfo, int length) {
    struct reportError_t *arg = userInfo;
    NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:arg->result
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"Error while streaming audio: Code %d", @""), arg->result]}];
    [[NSNotificationCenter defaultCenter] postNotificationName:MPIStreamerDidEncounterErrorNotification
                                                        object:(__bridge id)arg->THIS
                                                      userInfo:@{kMPIStreamerErrorKey: error}];
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
        
        for (NSUInteger i = 0; i < THIS->_buffer->mNumberBuffers; i++) {
            AudioBuffer audioBuffer = THIS->_buffer->mBuffers[i];
            [THIS->_audioStream writeData:audioBuffer.mData maxLength:audioBuffer.mDataByteSize];
            
            NSLog(@"buffer size: %u", (unsigned int)audioBuffer.mDataByteSize);
        }
    }
}

-(AEAudioControllerAudioCallback)receiverCallback {
    return audioCallback;
}


#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    switch (event) {
        case TDAudioStreamEventWantsData:
            //[self sendDataChunk];
            break;
            
        case TDAudioStreamEventError:
            // TODO: shit!
            NSLog(@"AudioOutputStreamer Stream Error");
            break;
            
        case TDAudioStreamEventEnd:
            // TODO: shit!
            NSLog(@"AudioOutputStreamer Stream Ended");
            break;
            
        default:
            break;
    }
}

@end
