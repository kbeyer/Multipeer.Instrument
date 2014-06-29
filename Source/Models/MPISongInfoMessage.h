//
//  MPISongInfoMessage.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/26/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "ActionMessage.h"

@interface MPISongInfoMessage : MPIActionMessage

@property (readwrite) NSString* title;
@property (readwrite) NSString* artist;
@property (readwrite) UIImage* artwork;

@end
