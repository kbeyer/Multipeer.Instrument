//
//  MPIAudioManager.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "AudioManager.h"
#import "TheAmazingAudioEngine.h"
#import "AEPlaythroughChannel.h"
#import "AEExpanderFilter.h"
#import "AELimiterFilter.h"
#import "AERecorder.h"
#import "MPIInputStreamChannel.h"
#import "MPIAudioStreamer.h"



static const int kInputChannelsChangedContext;

@interface MPIAudioManager(){
    AudioFileID _audioUnitFile;
    AEChannelGroupRef _group;
}
// dictionary of available AEAudioFilePlayer loops
@property (nonatomic, retain) NSMutableDictionary *loops; @property (nonatomic, retain) AEBlockChannel *oscillator;
@property (nonatomic, retain) AEAudioUnitChannel *audioUnitPlayer;
@property (nonatomic, retain) AEAudioFilePlayer *oneshot;
@property (nonatomic, retain) AEPlaythroughChannel *playthrough;
@property (nonatomic, retain) AELimiterFilter *limiter;
@property (nonatomic, retain) AEExpanderFilter *expander;
@property (nonatomic, retain) AEAudioUnitFilter *reverb;

//@property (nonatomic, retain) id<AEAudioReceiver> micReceiver;
@property (nonatomic, retain) MPIAudioStreamer *micReceiver;

@property (nonatomic, retain) MPIInputStreamChannel *inputStreamChannel;

@end

@implementation MPIAudioManager

@synthesize audioController = _audioController;

+ (AudioStreamBasicDescription)DefaultAudioDescription
{
    /*
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz
     
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= 44100.0;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
    return audioFormat;
     */
    
    
    AudioStreamBasicDescription audioDescription;
    memset(&audioDescription, 0, sizeof(audioDescription));
    audioDescription.mFormatID          = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsNonInterleaved;
    audioDescription.mChannelsPerFrame  = 1;
    audioDescription.mBytesPerPacket    = sizeof(SInt16);
    audioDescription.mFramesPerPacket   = 1;
    audioDescription.mBytesPerFrame     = sizeof(SInt16);
    audioDescription.mBitsPerChannel    = 8 * sizeof(SInt16);
    audioDescription.mSampleRate        = 44100.0;
    return audioDescription;
}

- (id)init{
    self = [super init];
    if (self) {
        // Create an instance of the audio controller, set it up and start it running
        //AEAudioController* ac = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled:YES];
        
        AEAudioController* ac = [[AEAudioController alloc] initWithAudioDescription:MPIAudioManager.DefaultAudioDescription inputEnabled:YES];
        
        ac.preferredBufferDuration = 0.005;
        [ac start:NULL];
        return [self initWithAudioController:ac];
    }
    return self;
}

- (id)initWithAudioController:(AEAudioController*)audioController {
    
    self.audioController = audioController;
    
    _loops = [NSMutableDictionary new];
    // Create the first loop player
    AEAudioFilePlayer* loop1 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Southern Rock Drums" withExtension:@"m4a"]
                                           audioController:_audioController
                                                     error:NULL];
    loop1.volume = 1.0;
    loop1.channelIsMuted = YES;
    loop1.loop = YES;
    [_loops setObject:loop1 forKey:@"drums"];
    
    // Create the second loop player
    AEAudioFilePlayer* loop2 = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Southern Rock Organ" withExtension:@"m4a"]
                                           audioController:_audioController
                                                     error:NULL];
    loop2.volume = 1.0;
    loop2.channelIsMuted = YES;
    loop2.loop = YES;
    [_loops setObject:loop2 forKey:@"organ"];
    
    // Create a block-based channel, with an implementation of an oscillator
    __block float oscillatorPosition = 0;
    __block float oscillatorRate = 622.0/44100.0;
    self.oscillator = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
                                                         UInt32           frames,
                                                         AudioBufferList *audio) {
        for ( int i=0; i<frames; i++ ) {
            // Quick sin-esque oscillator
            float x = oscillatorPosition;
            x *= x; x -= 1.0; x *= x;       // x now in the range 0...1
            x *= INT16_MAX;
            x -= INT16_MAX / 2;
            oscillatorPosition += oscillatorRate;
            if ( oscillatorPosition > 1.0 ) oscillatorPosition -= 2.0;
            
            ((SInt16*)audio->mBuffers[0].mData)[i] = x;
            ((SInt16*)audio->mBuffers[1].mData)[i] = x;
        }
    }];
    _oscillator.audioDescription = [AEAudioController nonInterleaved16BitStereoAudioDescription];
    
    _oscillator.channelIsMuted = YES;
    
    // Create an audio unit channel (a file player)
    self.audioUnitPlayer = [[AEAudioUnitChannel alloc] initWithComponentDescription:AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Generator, kAudioUnitSubType_AudioFilePlayer)
                                                                     audioController:_audioController
                                                                               error:NULL];
    
    //// Create a group for loop1, loop2 and oscillator
    _group = [_audioController createChannelGroup];
    [_audioController addChannels:[NSArray arrayWithObjects:loop1, loop2, _oscillator, nil] toChannelGroup:_group];
    
    // Finally, add the audio unit player
    //[_audioController addChannels:[NSArray arrayWithObjects:_audioUnitPlayer, nil]];
    
    [_audioController addObserver:self forKeyPath:@"numberOfInputChannels" options:0 context:(void*)&kInputChannelsChangedContext];
    
    return self;
}

-(void)dealloc {
    [_audioController removeObserver:self forKeyPath:@"numberOfInputChannels"];
    
    if ( _audioUnitFile ) {
        AudioFileClose(_audioUnitFile);
    }
    
    NSMutableArray *channelsToRemove = [NSMutableArray new];
    
    [channelsToRemove addObject:[_loops objectForKey:@"drums"]];
    [channelsToRemove addObject:[_loops objectForKey:@"organ"]];
    
    if ( _oneshot ) {
        [channelsToRemove addObject:_oneshot];
        self.oneshot = nil;
    }
    
    if ( _playthrough ) {
        [channelsToRemove addObject:_playthrough];
        [_audioController removeInputReceiver:_playthrough];
        self.playthrough = nil;
    }
    
    [_audioController removeChannels:channelsToRemove];
    
    if ( _limiter ) {
        [_audioController removeFilter:_limiter];
        self.limiter = nil;
    }
    
    if ( _expander ) {
        [_audioController removeFilter:_expander];
        self.expander = nil;
    }
    
    if ( _reverb ) {
        [_audioController removeFilter:_reverb];
        self.reverb = nil;
    }
    
    self.loops = nil;
    self.audioController = nil;
}

-(void)muteLoop:(BOOL)mute name:(NSString*)key {
    AEAudioFilePlayer* player = [_loops objectForKey:key];
    player.channelIsMuted = mute;
}
-(void)setLoopVolume:(float)volume name:(NSString*)key {
    AEAudioFilePlayer* player = [_loops objectForKey:key];
    if (!player.channelIsPlaying) {
        player.loop = YES;
    }
    player.volume = volume;
}


-(void)openMic:(NSOutputStream *)stream
{
    self.micReceiver = [[MPIAudioStreamer alloc] initWithAudioController:_audioController];
    [_micReceiver beginStreaming:stream];
    [_audioController addInputReceiver:_micReceiver];
    
}
-(void)closeMic
{
    [_micReceiver finishStreaming];
    [_audioController removeInputReceiver:_micReceiver];
    self.micReceiver = nil;
}


-(void)playStream:(NSInputStream*)stream
{
    self.inputStreamChannel = [[MPIInputStreamChannel alloc] initWithAudioController:_audioController stream:stream];
    _inputStreamChannel.channelIsMuted = NO;
    [_audioController addChannels:[NSArray arrayWithObjects:_inputStreamChannel, nil]];
    [_inputStreamChannel start];
}

-(void)stopStream
{
    [_inputStreamChannel stop];
    [_audioController removeChannels:@[_inputStreamChannel]];
    self.inputStreamChannel = nil;
}


@end
