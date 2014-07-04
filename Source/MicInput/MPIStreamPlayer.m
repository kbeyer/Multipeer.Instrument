//
//  MPIStreamPlayer.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/3/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIStreamPlayer.h"
#import "TDAudioInputStreamer.h"
#import <libkern/OSAtomic.h>

#define checkStatus(status) \
if ( (status) != noErr ) {\
NSLog(@"Error: %ld -> %s:%d", (status), __FILE__, __LINE__);\
}

@interface MPIStreamPlayer () {
    AudioBufferList              *_audio;
    UInt32                        _lengthInFrames;
    AudioStreamBasicDescription   _audioDescription;
    volatile int32_t              _playhead;
}
@property (nonatomic, strong, readwrite) TDAudioInputStreamer *streamer;
@end

@implementation MPIStreamPlayer
@synthesize stream = _stream, volume=_volume, pan=_pan, channelIsPlaying=_channelIsPlaying, channelIsMuted=_channelIsMuted, removeUponFinish=_removeUponFinish, completionBlock = _completionBlock;
@dynamic currentTime;

+ (id)audioStreamPlayer:(NSInputStream *)stream audioController:(AEAudioController *)audioController error:(NSError **)error {
    
    MPIStreamPlayer *player = [[self alloc] init];
    player->_volume = 1.0;
    player->_channelIsPlaying = YES;
    player->_audioDescription = audioController.audioDescription;
    player.streamer = [[TDAudioInputStreamer alloc] initWithInputStream:stream audioController:audioController];
    
    
    [player.streamer start];
    
    player->_audio = player.streamer.bufferList;
    
    
    return player;
}

- (void)dealloc {
    if ( _audio ) {
        for ( int i=0; i<_audio->mNumberBuffers; i++ ) {
            free(_audio->mBuffers[i].mData);
        }
        free(_audio);
    }
}

static void notifyPlaybackStopped(AEAudioController *audioController, void *userInfo, int length) {
    __unsafe_unretained MPIStreamPlayer *THIS = (__bridge MPIStreamPlayer*)*(void**)userInfo;
    THIS.channelIsPlaying = NO;
    
    if ( THIS->_removeUponFinish ) {
        [audioController removeChannels:@[THIS]];
    }
    
    if ( THIS.completionBlock ) THIS.completionBlock();
    
    THIS->_playhead = 0;
}

static OSStatus renderCallback(__unsafe_unretained MPIStreamPlayer *THIS, __unsafe_unretained AEAudioController *audioController, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio) {
    int32_t playhead = THIS->_playhead;
    int32_t originalPlayhead = playhead;
    
    if ( !THIS->_channelIsPlaying ) return noErr;
    
    // Get pointers to each buffer that we can advance
    char *audioPtrs[audio->mNumberBuffers];
    for ( int i=0; i<audio->mNumberBuffers; i++ ) {
        audioPtrs[i] = audio->mBuffers[i].mData;
    }
    
    int bytesPerFrame = THIS->_audioDescription.mBytesPerFrame;
    int remainingFrames = frames;
    
    // Copy audio in contiguous chunks, wrapping around if we're looping
    while ( remainingFrames > 0 ) {
        // The number of frames left before the end of the audio
        int framesToCopy = MIN(remainingFrames, THIS->_lengthInFrames - playhead);
        
        // Fill each buffer with the audio
        for ( int i=0; i<audio->mNumberBuffers; i++ ) {
            memcpy(audioPtrs[i], ((char*)THIS->_audio->mBuffers[i].mData) + playhead * bytesPerFrame, framesToCopy * bytesPerFrame);
            
            // Advance the output buffers
            audioPtrs[i] += framesToCopy * bytesPerFrame;
        }
        
        // Advance playhead
        remainingFrames -= framesToCopy;
        playhead += framesToCopy;
        
    }
    
    OSAtomicCompareAndSwap32(originalPlayhead, playhead, &THIS->_playhead);
    
    return noErr;
}

-(AEAudioControllerRenderCallback)renderCallback {
    return &renderCallback;
}

@end
