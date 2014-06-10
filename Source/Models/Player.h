//
//  MPIPlayer.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MTLModel.h"
#import "MTLJsonAdapter.h"

@interface MPIPlayer : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString* uuid;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* phone;
@property (nonatomic, copy) NSDate* lastActive;

@end
