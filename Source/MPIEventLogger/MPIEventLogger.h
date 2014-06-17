//
//  MPIEventLogger.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPIEvent.h"

// available log destinations
typedef NS_ENUM(NSUInteger, MPILogDestination) {
    MPILogDestinationConsole,
    MPILogDestinationAPI,
    MPILogDestinationALL
};

// available logging levels
typedef NS_ENUM(NSUInteger, MPILoggerLevel) {
    MPILoggerLevelOff,
    MPILoggerLevelDebug,
    MPILoggerLevelInfo,
    MPILoggerLevelWarn,
    MPILoggerLevelError,
    MPILoggerLevelFatal
};

@interface MPIEventLogger : NSObject

// Single shared instance is created on first call to sharedInstance
+ (MPIEventLogger*)sharedInstance;

// The logLevel will be used to filter which log requests are processed
// To stop processing events, set to MPILoggerLevelOff
// The default logLevel (if not explicitly set) is MPILoggerLevelInfo
// This can be changed at any time and will apply to all future log requests after a change
@property (readwrite) MPILoggerLevel logLevel;

// The destination will determine where log events are sent
// To send to all destinations, use MPILogDestinationALL (the default)
// This can be changed at any time and will apply to all future events after a change
@property (readwrite) MPILogDestination logDestination;

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
