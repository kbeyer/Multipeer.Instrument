//
//  EventLogger.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIEventLogger.h"
#import "MPIEvent.h"
#import "Reachability.h"

/* Override for NSLog */
void MPILog(MPILoggerLevel level, NSString *source, NSString* description)
{
    [[MPIEventLogger sharedInstance] log:level source:source description:description];
}


// kDefaultLogLevel is used both as default level when starting the Logger
// AND as the default level when calling log without a level specified
static MPILoggerLevel const kDefaultLogLevel = MPILoggerLevelInfo;

// kDefaultLogDestination is used to configure where events should be logged
// in the case it is not configured explicitly
static MPILogDestination const kDefaultLogDestination = MPILogDestinationALL;

static NSString* const kApiHost = @"k6beventlogger.herokuapp.com";

@interface MPIEventLogger()
// re-usable url session for API calls
@property (nonatomic, strong) NSURLSession *urlSession;
// track reachability to api
@property (readwrite) BOOL apiIsReachable;
@end

@implementation MPIEventLogger

- (id)init {
    self = [super init];
    if (self) {
        _timeDeltaSeconds = 0;
        // track if api url is reachable
        [self setupReachability];
        // initial configuration
        _logDestination = kDefaultLogDestination;
        _logLevel = kDefaultLogLevel;
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}


+ (MPIEventLogger *)sharedInstance
{
    static MPIEventLogger* sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MPIEventLogger alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark - log overloads

/*
 * Simple version of log requires only source and description
 * Defaults fall through to version with all parameters used to create MPIEvent object
 * Note that the Event start and end will default to the creation time for object if not specified
 * The default level is Info
 *
 * @param source - string to identify the source of the Event
 * @param description - friendly display text for the Event
 */
- (MPIEventPersistence)log:(NSString*)source description:(NSString*)description {
    return [self log:kDefaultLogLevel source:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description {
    return [self log:level source:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self log:level source:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self log:level source:source description:description
                 tags:tags
                start:start
                  end:[[NSDate alloc] init]
                 data:nil];
}
- (MPIEventPersistence)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self log:level source:source description:description
                 tags:tags
                start:start
                  end:end
                 data:nil];
}
- (MPIEventPersistence)log:(MPILoggerLevel)level
    source:(NSString*)source
description:(NSString*)description
      tags:(NSArray*)tags
     start:(NSDate*)start
       end:(NSDate*)end
      data:(NSDictionary*)data {
    
    // ignore requests to log events that are below current max level
    if (_logLevel < level) {
        return MPIEventPersistenceIgnore;
    }
    
    // create event object with device id set to current device name
    NSString* deviceName = [[UIDevice currentDevice] name];
    MPIEvent* evt = [[MPIEvent alloc] init:level
                                    source:source
                               displayText:description
                                      tags:tags
                                     start:[self timeWithOffset:start]
                                       end:[self timeWithOffset:end]
                                      data:data
                                  deviceID:deviceName
                                    fnName:nil];
    
    MPIEventPersistence status = MPIEventPersistenceSuccess;
    // log to specified destination
    switch(_logDestination){
        case MPILogDestinationConsole:
            printf("%s\n",[[NSString stringWithFormat:@"[MPIEvent][%@] %@", source, description] UTF8String]);
            break;
        case MPILogDestinationAPI:
            status = [self persist:evt];
            break;
        case MPILogDestinationALL:
            status = [self persist:evt];
            printf("%s\n",[[NSString stringWithFormat:@"[MPIEvent][%@] %@", source, description] UTF8String]);
            break;
    }
    return status;
}


#pragma mark - debug overloads

/*
 * Overloads for DEBUG level
 */
- (MPIEventPersistence)debug:(NSString *)source description:(NSString *)description {
     return [self debug:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
 }
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self debug:source description:description
                tags:tags
               start:[[NSDate alloc] init]
                 end:nil
                data:nil];
}
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self debug:source description:description
                tags:tags
               start:start
                 end:nil
                data:nil];
}
- (MPIEventPersistence)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self debug:source description:description
                tags:tags
               start:start
                 end:end
                data:nil];
}
- (MPIEventPersistence)debug:(NSString*)source
description:(NSString*)description
       tags:(NSArray*)tags
      start:(NSDate*)start
        end:(NSDate*)end
       data:(NSDictionary*)data {
    return [self log:MPILoggerLevelDebug
              source:source
         description:description
                  tags:tags
                 start:start
                   end:end
                  data:data];
}

#pragma mark - info overloads

/*
 * Overloads for INFO level
 */
- (MPIEventPersistence)info:(NSString *)source description:(NSString *)description {
    return [self info:source description:description
                  tags:[[NSArray alloc] init]
                 start:[[NSDate alloc] init]
                   end:nil
                  data:nil];
}
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self info:source description:description
                  tags:tags
                 start:[[NSDate alloc] init]
                   end:nil
                  data:nil];
}
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self info:source description:description
                  tags:tags
                 start:start
                   end:nil
                  data:nil];
}
- (MPIEventPersistence)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self info:source description:description
                  tags:tags
                 start:start
                   end:end
                  data:nil];
}
- (MPIEventPersistence)info:(NSString*)source
  description:(NSString*)description
         tags:(NSArray*)tags
        start:(NSDate*)start
          end:(NSDate*)end
         data:(NSDictionary*)data {
    return [self log:MPILoggerLevelInfo
              source:source
         description:description
                tags:tags
               start:start
                 end:end
                data:data];
}


#pragma mark - warn overloads

/*
 * Overloads for WARN level
 */
- (MPIEventPersistence)warn:(NSString *)source description:(NSString *)description {
    return [self warn:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self warn:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self warn:source description:description
                 tags:tags
                start:start
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self warn:source description:description
                 tags:tags
                start:start
                  end:end
                 data:nil];
}
- (MPIEventPersistence)warn:(NSString*)source
 description:(NSString*)description
        tags:(NSArray*)tags
       start:(NSDate*)start
         end:(NSDate*)end
        data:(NSDictionary*)data {
    return [self log:MPILoggerLevelWarn
              source:source
         description:description
                tags:tags
               start:start
                 end:end
                data:data];
}


#pragma mark - error overloads

/*
 * Overloads for ERROR level
 */
- (MPIEventPersistence)error:(NSString *)source description:(NSString *)description {
    return [self error:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self error:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self error:source description:description
                 tags:tags
                start:start
                  end:nil
                 data:nil];
}
- (MPIEventPersistence)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self error:source description:description
                 tags:tags
                start:start
                  end:end
                 data:nil];
}
- (MPIEventPersistence)error:(NSString*)source
 description:(NSString*)description
        tags:(NSArray*)tags
       start:(NSDate*)start
         end:(NSDate*)end
        data:(NSDictionary*)data {
    return [self log:MPILoggerLevelError
              source:source
         description:description
                tags:tags
               start:start
                 end:end
                data:data];
}




#pragma mark - send to API

- (MPIEventPersistence)persist:(MPIEvent*)evt {
    // validate event parameter
    if (!evt || !evt.isValid) {
        
        printf("%s\n",[[NSString stringWithFormat:@"[MPIEvent] INVALID. %@", evt] UTF8String]);
        return MPIEventPersistenceError; //validation
    }
    
    // IF API is not reachable ... return false
    if (_apiIsReachable == NO) {
        return MPIEventPersistenceOffline;
    }
    
    NSString* baseURL = [[NSString alloc] initWithFormat:@"http://%@/api/v1/", kApiHost];
    NSString* messagesPath = [baseURL stringByAppendingPathComponent:@"events"];
    
    NSURL* url = [NSURL URLWithString:messagesPath]; //create url
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    // serialize as JSON dictionary
    NSDictionary* json = [MTLJSONAdapter JSONDictionaryFromModel:evt];
    
    //create data via dictionary
    NSData* data = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
    request.HTTPBody = data;
    
    //set content type
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // TEST : some of the request seem to be dropped ... testing with new session every time
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _urlSession = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            //NSArray* responseArray = @[[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]];
            //NSLog(@"request completed");
        } else {
            printf("%s\n",[[NSString stringWithFormat:@"Error saving log event to API. %@", error] UTF8String]);
        }
    }];
    [dataTask resume];
    return MPIEventPersistenceSuccess;
}


#pragma mark - Track reachability to API
- (void)setupReachability
{
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:kApiHost];
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        printf("%s\n",[[NSString stringWithFormat:@"API is REACHABLE!"] UTF8String]);
        _apiIsReachable = YES;
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        printf("%s\n",[[NSString stringWithFormat:@"API is UNREACHABLE!"] UTF8String]);
        _apiIsReachable = NO;
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

#pragma mark - time offset helper
// returns the system time plus delta based on time sync process
- (NSDate*)timeWithOffset:(NSDate*)date
{
    if(date == nil) {
        return nil;
    }
    return [NSDate dateWithTimeInterval:_timeDeltaSeconds sinceDate:date];
}

@end

