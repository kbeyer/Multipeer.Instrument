//
//  MPIAudioStreamer.h
//  Multipeer.Instrument
//
//  Inspired by AERecord
//
//  Created by Kyle Beyer on 7/3/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//


#ifdef __cplusplus
extern "C" {
#endif
    
#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine.h"
    
extern NSString * MPIStreamerDidEncounterErrorNotification;
extern NSString * kMPIStreamerErrorKey;

/*!
 * Streaming utility, used for streaming live audio
 *
 *  This can be used to stream just the microphone input, or the output of the
 *  audio system, just one channel, or a combination of all three. Simply add an
 *  instance of this class as an audio receiver for the particular audio you wish
 *  to record, using AEAudioController's [addInputReceiver:](@ref AEAudioController::addInputReceiver:),
 *  [addOutputReceiver:](@ref AEAudioController::addOutputReceiver:),
 *  [addOutputReceiver:forChannel:](@ref AEAudioController::addOutputReceiver:forChannel:), etc, and all
 *  streams will be mixed together and recorded.
 *
 */
@interface MPIAudioStreamer : NSObject<AEAudioReceiver, NSStreamDelegate>


/*!
 * Determine whether AAC encoding is possible on this device
 */
+ (BOOL)AACEncodingAvailable;

/*!
 * Initialise
 *
 * @param audioController The Audio Controller
 */
- (id)initWithAudioController:(AEAudioController*)audioController;

/*!
 * Prepare and begin streaming
 *
 *  Prepare to stream, then start streaming immediately
 *
 * @param stream The NSOutputStream to stream to */
- (void)beginStreaming:(NSOutputStream*)stream;


/*!
 * Finish streaming and close file
 */
- (void)finishStreaming;


/*!
 * Current recorded time in seconds
 */
@property (nonatomic, readonly) double currentTime;

@end
    
#ifdef __cplusplus
}
#endif