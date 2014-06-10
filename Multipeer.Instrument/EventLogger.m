//
//  EventLogger.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "EventLogger.h"
#import "Message.h"

static NSString* const kBaseURL = @"http://localhost:3000";

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

- (void)log:(id)msg {
    [self persist:msg];
}

- (void)persist:(MPIMessage*)msg {

    if (!msg || msg.type == nil || msg.type.length == 0) {
        return; //validation
    }
    
    NSString* messagesPath = [kBaseURL stringByAppendingPathComponent:@"messages"];
    
    NSURL* url = [NSURL URLWithString:messagesPath]; //1
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST"; //2
    
    // serialize as JSON dictionary
    NSDictionary* json = [MTLJSONAdapter JSONDictionaryFromModel:msg];
    
    NSData* data = [NSJSONSerialization dataWithJSONObject:json options:0 error:NULL]; //3
    request.HTTPBody = data;
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"]; //4
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
        if (!error) {
            //NSArray* responseArray = @[[NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]];
            NSLog(@"request completed");
        }
    }];
    [dataTask resume];
}

@end

