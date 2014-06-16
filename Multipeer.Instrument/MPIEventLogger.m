//
//  EventLogger.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MPIEventLogger.h"
#import "MPIEvent.h"

static NSString* const kBaseURL = @"http://multipeernode.herokuapp.com/";

@interface MPIEventLogger()
@end

@implementation MPIEventLogger

- (id)init {
    
    self = [super init];
    if (self) {
        // initial configuration
        [self configure];
    }
    return self;
}

- (void)configure {
    _logDestination = MPILogToAPI;
    _defaultLogLevel = MPILoggerLevelInfo;
}

+ (MPIEventLogger *)instance
{
    static MPIEventLogger* sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MPIEventLogger alloc] init];
    });
    
    return sharedInstance;
}


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
    return [self log:_defaultLogLevel source:source description:description
                 tags:[[NSArray alloc] initWithObjects:@"Undefined", nil]
                start:[[NSDate alloc] init]
                  end:[[NSDate alloc] init]
                 data:nil];
}
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description {
    return [self log:level source:source description:description
                 tags:[[NSArray alloc] initWithObjects:@"Undefined", nil]
                start:[[NSDate alloc] init]
                  end:[[NSDate alloc] init]
                 data:nil];
}
- (void)log:(MPILoggerLevel)level source:(NSString*)source description:(NSString*)description tags:(NSArray*)tags {
    return [self log:level source:source description:description
                 tags:tags
                start:[[NSDate alloc] init]
                  end:[[NSDate alloc] init]
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
    
    NSString* deviceName = [[UIDevice currentDevice] name];
    MPIEvent* evt = [[MPIEvent alloc] init:level source:source description:description tags:tags start:start end:end data:data deviceID:deviceName];
    
    // log to specified destination
    switch(_logDestination){
        case MPILogToConsole:
            NSLog(@"[MPIEvent] %@", evt);
            break;
        case MPILogToAPI:
            [self persist:evt];
            break;
        case MPILogToALL:
            [self persist:evt];
            NSLog(@"[MPIEvent] %@", evt);
            break;
    }
}


- (void)persist:(MPIEvent*)evt {
    // validate event parameter
    if (!evt || !evt.isValid) {
        
        NSLog(@"[MPIEvent] INVALID. %@", evt);
        return; //validation
    }
    
    NSString* messagesPath = [kBaseURL stringByAppendingPathComponent:@"messages"];
    
    NSURL* url = [NSURL URLWithString:messagesPath]; //create url
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST"; //2
    
    // serialize as JSON dictionary
    NSDictionary* json = [MTLJSONAdapter JSONDictionaryFromModel:evt];
    
    //create data via dictionary
    NSData* data = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL];
    request.HTTPBody = data;
    
    //set content type
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            //NSArray* responseArray = @[[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]];
            NSLog(@"request completed");
        }
    }];
    [dataTask resume];
}

@end

