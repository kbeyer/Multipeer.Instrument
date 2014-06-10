//
//  MPIGame.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "BaseModel.h"
#import "JoinRequest.h"
#import "ActionMessage.h"
#import "Player.h"

@interface MPIGame : MPIBaseModel

@property (readwrite) NSString* uuid;
@property (readwrite) NSMutableArray* players;
@property (readwrite) float volume;
@property (readwrite) float color;

- (void)handleJoinRequest:(MPIJoinRequest *)request;
- (void)handleActionRequest:(MPIActionMessage *)action;
- (void) addUpdatePlayer: (MPIPlayer *)player;
- (void) removePlayer: (NSString *)uuid;

- (void)requestFlashChange:(NSString *)playerUUID value:(float)val;
- (void)requestSoundChange:(NSString *)playerUUID value:(float)val;
- (void)requestColorChange:(NSString *)playerUUID value:(float)val;

@end
