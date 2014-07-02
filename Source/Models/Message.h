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

+ (NSDateFormatter *)dateFormatter;

@property (nonatomic, copy) NSString* type;
@property (nonatomic, copy) NSNumber* val;
@property (nonatomic, copy) NSDate* createdAt;

@end
