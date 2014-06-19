//
//  EventLogger.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIEventLogger.h"
#import "MPIEvent.h"

// kDefaultLogLevel is used both as default level when starting the Logger
// AND as the default level when calling log without a level specified
static MPILoggerLevel const kDefaultLogLevel = MPILoggerLevelInfo;

// kDefaultLogDestination is used to configure where events should be logged
// in the case it is not configured explicitly
static MPILogDestination const kDefaultLogDestination = MPILogDestinationALL;

// kBaseURL is used as the root for events sent to MPILogToAPI destination
static NSString* const kBaseURL = @"http://k6beventlogger.herokuapp.com/api/v1/";

@interface MPIEventLogger()
// re-usable url session for API calls
@property (nonatomic, strong) NSURLSession *urlSession;
@end

@implementation MPIEventLogger

- (id)init {
    self = [super init];
    if (self) {
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
- (void)log:(NSString*)source description:(NSString*)description {
    return [self log:kDefaultLogLevel source:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description {
    return [self log:level source:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self log:level source:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self log:level source:source description:description
                 tags:tags
                start:start
                  end:[[NSDate alloc] init]
                 data:nil];
}
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self log:level source:source description:description
                 tags:tags
                start:start
                  end:end
                 data:nil];
}
- (void)log:(MPILoggerLevel)level
    source:(NSString*)source
description:(NSString*)description
      tags:(NSArray*)tags
     start:(NSDate*)start
       end:(NSDate*)end
      data:(NSDictionary*)data {
    
    // ignore requests to log events that are below current max level
    if (_logLevel < level) {
        return;
    }
    
    // create event object with device id set to current device name
    NSString* deviceName = [[UIDevice currentDevice] name];
    MPIEvent* evt = [[MPIEvent alloc] init:level
                                    source:source
                               description:description
                                      tags:tags
                                     start:start
                                       end:end
                                      data:data
                                  deviceID:deviceName
                                    fnName:nil];
    
    // log to specified destination
    switch(_logDestination){
        case MPILogDestinationConsole:
            NSLog(@"[MPIEvent][%@] %@", source, description);
            break;
        case MPILogDestinationAPI:
            [self persist:evt];
            break;
        case MPILogDestinationALL:
            [self persist:evt];
            NSLog(@"[MPIEvent][%@] %@", source, description);
            break;
    }
}


#pragma mark - debug overloads

/*
 * Overloads for DEBUG level
 */
- (void)debug:(NSString *)source description:(NSString *)description {
     return [self debug:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
 }
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self debug:source description:description
                tags:tags
               start:[[NSDate alloc] init]
                 end:nil
                data:nil];
}
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self debug:source description:description
                tags:tags
               start:start
                 end:nil
                data:nil];
}
- (void)debug:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self debug:source description:description
                tags:tags
               start:start
                 end:end
                data:nil];
}
- (void)debug:(NSString*)source
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
- (void)info:(NSString *)source description:(NSString *)description {
    return [self info:source description:description
                  tags:[[NSArray alloc] init]
                 start:[[NSDate alloc] init]
                   end:nil
                  data:nil];
}
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self info:source description:description
                  tags:tags
                 start:[[NSDate alloc] init]
                   end:nil
                  data:nil];
}
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self info:source description:description
                  tags:tags
                 start:start
                   end:nil
                  data:nil];
}
- (void)info:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self info:source description:description
                  tags:tags
                 start:start
                   end:end
                  data:nil];
}
- (void)info:(NSString*)source
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
- (void)warn:(NSString *)source description:(NSString *)description {
    return [self warn:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self warn:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self warn:source description:description
                 tags:tags
                start:start
                  end:nil
                 data:nil];
}
- (void)warn:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self warn:source description:description
                 tags:tags
                start:start
                  end:end
                 data:nil];
}
- (void)warn:(NSString*)source
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
- (void)error:(NSString *)source description:(NSString *)description {
    return [self error:source description:description
                 tags:[[NSArray alloc] init]
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self error:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:nil
                 data:nil];
}
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start {
    return [self error:source description:description
                 tags:tags
                start:start
                  end:nil
                 data:nil];
}
- (void)error:(NSString*)source description:(NSString*)description tags:(NSArray*)tags start:(NSDate*)start end:(NSDate*)end {
    return [self error:source description:description
                 tags:tags
                start:start
                  end:end
                 data:nil];
}
- (void)error:(NSString*)source
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

- (void)persist:(MPIEvent*)evt {
    // validate event parameter
    if (!evt || !evt.isValid) {
        
        NSLog(@"[MPIEvent] INVALID. %@", evt);
        return; //validation
    }
    
    NSString* messagesPath = [kBaseURL stringByAppendingPathComponent:@"events"];
    
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
            NSLog(@"request completed");
        }
    }];
    [dataTask resume];
}

@end

