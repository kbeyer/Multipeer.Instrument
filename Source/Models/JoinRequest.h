//
//  MPIJoinRequest.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "Message.h"

@interface MPIJoinRequest : MPIMessage

@property (readwrite) NSString* from_name;
@property (readwrite) NSString* from_uuid;

@end
