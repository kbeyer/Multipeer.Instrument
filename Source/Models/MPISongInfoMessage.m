//
//  MPISongInfoMessage.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/26/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPISongInfoMessage.h"

#define kMessageType @"song-info"

@implementation MPISongInfoMessage

@synthesize title, artist, artwork;

+ (NSString*) messageType {
    return kMessageType;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"title": @"title",
             @"artist": @"artist",
             @"artwork": @"artwork"
             };
}

@end
