//
//  EventLogger.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPIEventLogger : NSObject

+ (MPIEventLogger*)instance;


- (void)log:(id)msg;

@end
