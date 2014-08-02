//
//  MPIEvent.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/16/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIEvent.h"
#import "MPIEventLogger.h"
#import "MTLValueTransformer.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"

@implementation MPIEvent

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    return dateFormatter;
}

+ (NSValueTransformer *)startJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [self.dateFormatter dateFromString:str];
    } reverseBlock:^(NSDate *date) {
        return [self.dateFormatter stringFromDate:date];
    }];
}
+ (NSValueTransformer *)endJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [self.dateFormatter dateFromString:str];
    } reverseBlock:^(NSDate *date) {
        return [self.dateFormatter stringFromDate:date];
    }];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"source": @"source",
             @"displayText": @"description",
             @"start": @"start",
             @"end": @"end",
             @"tags": @"tags",
             @"data": @"data",
             @"deviceID": @"device_id",
             @"logLevel": @"log_level",
             @"fnName": @"fn_name"
             };
}

/*
 * Advanced init currently accepts all properties.
 * The log functions are overloaded to help create with default values
 *
 * @param source - string to identify the source of the Event
 * @param displayText - friendly display text for the Event
 */
- (id)init:(MPILoggerLevel)level
            source:(NSString*)source
            displayText:(NSString*)displayText
            tags:(NSArray*)tags
            start:(NSDate*)start
            end:(NSDate*)end
            data:(NSDictionary*)data
            deviceID:(NSString *)deviceID
            fnName:(NSString *)fnName {
    
    self = [super init];
    if (self) {
        // initialize all properties
        _logLevel = level;
        _source = source;
        _displayText = displayText;
        _tags = tags;
        _start = start;
        _end = end;
        _data = data;
        _deviceID = deviceID;
        _fnName = fnName;
    }
    return self;
}

- (BOOL)isValid {
    return _source != nil && _start != nil && _displayText != nil;
}

@end
