//
//  MPIEventLogger.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPIEvent.h"

#undef MPILog

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

// status of event persistence
typedef NS_ENUM(NSUInteger, MPIEventPersistence) {
    MPIEventPersistenceSuccess,
    MPIEventPersistenceOffline,
    MPIEventPersistenceIgnore,
    MPIEventPersistenceError
};

#if __cplusplus
extern "C" {
#endif
    /* Override for NSLog */
    void MPILog(MPILoggerLevel level, NSString* source, NSString *description);
#if __cplusplus
}
#endif


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

// the time offset to be used for adjusting log time to match 'time server' or reference value
@property (nonatomic) double timeDeltaSeconds;
- (NSDate*)timeWithOffset:(NSDate*)date;

// overload the log method to support various levels of detail to specified
// for creation of the MPIEvent object
- (MPIEventPersistence)log:(NSString*)source description:(NSString*)description;
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description;
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for DEBUG level
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description;
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for INFO level
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description;
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for WARN level
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description;
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;

// overloads for ERROR level
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description;
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags;
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start;
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end;
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end data:(NSDictionary*)data;
@end
