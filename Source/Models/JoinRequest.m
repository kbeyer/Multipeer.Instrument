//
//  MPIJoinRequest.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "JoinRequest.h"

#define kMessageType @"join-request"

@implementation MPIJoinRequest

@synthesize from_name;

+ (NSString*) messageType {
    return kMessageType;
}

- (BOOL) isValid {
    if (self.from_name) {
        return YES;
    }
    return NO;
}

@end
