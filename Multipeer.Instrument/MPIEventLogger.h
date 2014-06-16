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

// the maxLogLevel will be used to filter which log requests are processed
@property (readwrite) MPILoggerLevel maxLogLevel;
// the destination will determine where log events are sent
@property (readwrite) MPILogDestination logDestination;

// helper function to stop processing log requests
- (void)stop;
// helper function to either restart logging at previously defined level
- (void)start;
// restart at specific level or change the level
- (void)start:(MPILoggerLevel)newLevel;
// restart at specific level or change the level and the destination
- (void)start:(MPILoggerLevel)newLevel destination:(MPILogDestination)newDestination;

// overload the log method to support various levels of detail to specified
// for creation of the MPIEvent object
- (void)log:(NSString*)source description:(NSString*)description;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for DEBUG level
- (void)debug:(NSString*)source description:(NSString*)description;
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for INFO level
- (void)info:(NSString*)source description:(NSString*)description;
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for WARN level
- (void)warn:(NSString*)source description:(NSString*)description;
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for ERROR level
- (void)error:(NSString*)source description:(NSString*)description;
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;
@end
