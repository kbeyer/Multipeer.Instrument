//
//  MPIGameManager.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionController.h"
#import "TDAudioStreamer.h"
#import "MPISongInfoMessage.h"
#import "MPIMotionManager.h"

@interface MPIGameManager : NSObject<MPISessionControllerDelegate, MPIMotionManagerDelegate>

+ (MPIGameManager*)instance;

@property (strong, nonatomic) MPISessionController *sessionController;

// the time offset from 'server' or reference player acting as 'time server'
@property (nonatomic) double timeDeltaSeconds;

// initiates simple algorithm to calculate system time delta with specified player
- (void)calculateTimeDeltaFrom:(id)playerID;
// returns the system time plus delta based on time sync process
- (NSDate*)currentTime;


@property (readwrite) NSNumber* volume;
@property (readwrite) NSNumber* color;
@property (strong, nonatomic) TDAudioInputStreamer *audioInStream;
@property (readwrite) MPISongInfoMessage *lastSongMessage;

- (void)requestFlashChange:(id)playerID value:(NSNumber*)val;
- (void)requestSoundChange:(id)playerID value:(NSNumber*)val;
- (void)requestColorChange:(id)playerID value:(NSNumber*)val;
- (void)requestTimeSync:(id)playerID value:(NSNumber*)val;

// handles time sync process
- (void)recievedTimestamp:(id)playerID value:(NSNumber*)val;

- (void)handleActionRequest:(NSDictionary*)json type:(NSString*)type;


- (void)startEcho:(NSOutputStream*)stream;
- (void)stopEcho;

- (void)startup;
- (void)shutdown;
@end
