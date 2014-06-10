//
//  MPIActionMessage.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "ActionMessage.h"

#define kMessageType @"action-request"

@implementation MPIActionMessage

@synthesize actionname, actionvalue;

+ (NSString*) messageType {
    return kMessageType;
}

- (BOOL) isValid {
    if (self.actionname) {
        return YES;
    }
    return NO;
}

@end
