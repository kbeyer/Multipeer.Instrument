//
//  MPIEventLogger.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPIEvent.h"

typedef NS_ENUM(NSUInteger, MPILogDestination) {
    MPILogToConsole,
    MPILogToAPI,
    MPILogToALL
};

typedef NS_ENUM(NSUInteger, MPILoggerLevel) {
    MPILoggerLevelOff,
    MPILoggerLevelDebug,
    MPILoggerLevelInfo,
    MPILoggerLevelWarn,
    MPILoggerLevelError,
    MPILoggerLevelFatal = MPILoggerLevelOff,
};

@interface MPIEventLogger : NSObject

+ (MPIEventLogger*)instance;


@property (readwrite) MPILoggerLevel defaultLogLevel;
@property (readwrite) MPILogDestination logDestination;

// overload the log method to support various levels of detail to specified
// for creation of the MPIEvent object
- (void)log:(NSString*)source description:(NSString*)description;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

@end
