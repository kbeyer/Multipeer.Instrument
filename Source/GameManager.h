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


@property (readwrite) NSNumber* volume;
@property (readwrite) NSNumber* color;


- (void)requestFlashChange:(id)playerID value:(NSNumber*)val;
- (void)requestSoundChange:(id)playerID value:(NSNumber*)val;
- (void)requestColorChange:(id)playerID value:(NSNumber*)val;
- (void)handleActionRequest:(NSString*)type value:(NSNumber*)val;

@end
