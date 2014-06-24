//
//  MPIGameManager.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SessionController.h"

@interface MPIGameManager : NSObject<MPISessionControllerDelegate>

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

- (void)requestFlashChange:(id)playerID value:(NSNumber*)val;
- (void)requestSoundChange:(id)playerID value:(NSNumber*)val;
- (void)requestColorChange:(id)playerID value:(NSNumber*)val;
- (void)requestTimeSync:(id)playerID value:(NSNumber*)val;

// handles time sync process
- (void)recievedTimestamp:(id)playerID value:(NSNumber*)val;

- (void)handleActionRequest:(NSString*)type value:(NSNumber*)val;

@end
