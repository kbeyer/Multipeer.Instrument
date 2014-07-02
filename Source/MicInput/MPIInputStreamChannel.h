//
//  MPIInputStreamChannel.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/2/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#ifdef __cplusplus
extern "C" {
#endif
    
#import <Foundation/Foundation.h>
#import "TheAmazingAudioEngine.h"
    
// Input stream channel, used for playing audio from input stream
@interface MPIInputStreamChannel : NSObject

/*!
 * Initialise
 *
 * @param audioController The Audio Controller
 */
- (id)initWithAudioController:(AEAudioController*)audioController stream:(NSInputStream*)stream;

@property (nonatomic, assign) float volume;
@property (nonatomic, assign) float pan;
@property (nonatomic, assign) BOOL channelIsMuted;
@property (nonatomic, readonly) AudioStreamBasicDescription audioDescription;

- (void)start;
- (void)resume;
- (void)pause;
- (void)stop;

@end
    
#ifdef __cplusplus
}
#endif
