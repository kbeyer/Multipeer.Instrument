//
//  MPIStreamPlayer.h
//  Multipeer.Instrument
//
//  via AEAudioFilePlayer
//
//


#ifdef __cplusplus
extern "C" {
#endif
    
#import <Foundation/Foundation.h>
#import "AEAudioController.h"
    
    /*!
     * Audio stream player
     *
     *  This class allows you to play audio streams.
     *
     *  To use, create an instance, then add it to the audio controller.
     */
    @interface MPIStreamPlayer : NSObject <AEAudioPlayable>

/*!
 * Create a new player instance
 *
 * @param stream            stream to read from
 * @param audioController   The audio controller
 * @param error             If not NULL, the error on output
 * @return The audio player, ready to be @link AEAudioController::addChannels: added @endlink to the audio controller.
 */
+ (id)audioStreamPlayer:(NSInputStream*)stream audioController:(AEAudioController*)audioController error:(NSError**)error;

@property (nonatomic, strong, readonly) NSInputStream *stream;         //!< Original media stream
@property (nonatomic, assign) NSTimeInterval currentTime;   //!< Current playback position, in seconds
@property (nonatomic, readwrite) float volume;              //!< Track volume
@property (nonatomic, readwrite) float pan;                 //!< Track pan
@property (nonatomic, readwrite) BOOL channelIsPlaying;     //!< Whether the track is playing
@property (nonatomic, readwrite) BOOL channelIsMuted;       //!< Whether the track is muted
@property (nonatomic, readwrite) BOOL removeUponFinish;     //!< Whether the track automatically removes itself from the audio controller after playback completes
@property (nonatomic, copy) void(^completionBlock)();       //!< A block to be called when playback finishes
@end
    
#ifdef __cplusplus
}
#endif