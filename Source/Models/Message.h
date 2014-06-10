//
//  MPIMessage.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MTLModel.h"
#import "MTLJsonAdapter.h"

@interface MPIMessage : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString* type;
@property (nonatomic, copy) NSNumber* val;

@end
