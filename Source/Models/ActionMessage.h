//
//  MPIActionMessage.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "Message.h"

@interface MPIActionMessage : MPIMessage

@property (readwrite) NSString* actionname;
@property (readwrite) CGFloat actionvalue;
@property (readwrite) NSString* to_uuid;

@end
