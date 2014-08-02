//
//  MPIAppDelegate.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "AppDelegate.h"
#import "GameManager.h"
#import "TestFlight.h"
#import "MPIEventLogger.h"

@interface MPIAppDelegate()
@property (strong, nonatomic) UILocalNotification* expireNotification;
@property (nonatomic) UIBackgroundTaskIdentifier endSessionTaskId;
@end

@implementation MPIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // configure MPIEventLogger
    [self setupEventLogger];
    
    
    
    // initial game launch
    [[MPIGameManager instance] startup];
    
    //[TestFlight takeOff:@"ba6904ec-9673-47ca-a275-e1bd8ddeda07"];
    
    return YES;
}

- (void)setupEventLogger
{
     MPIEventLogger* logger = [MPIEventLogger sharedInstance];

    /*
    NSString* source = [[NSString alloc] initWithUTF8String:__PRETTY_FUNCTION__];
     // TEST: temp functions to test logging
     logger.logLevel = MPILoggerLevelDebug;
     [logger debug:source description:@"debug level test"];
     [logger info:source description:@"IGNORE ME"];
     logger.logLevel = MPILoggerLevelError;
     [logger error:source description:@"error level test"];
     [logger warn:source description:@"SHOW ME"];
     logger.logLevel = MPILoggerLevelInfo;
     [logger info:source description:@"info level test"];
     [logger warn:source description:@"IGNORE ME"];
     [logger debug:source description:@"SHOW ME"];
     logger.logLevel = MPILoggerLevelWarn;
     [logger warn:source description:@"warn level test"];
     [logger error:source description:@"IGNORE ME"];
     [logger info:source description:@"SHOW ME"];
     logger.logDestination = MPILogDestinationConsole;
     [logger info:source description:@"CONSOLE ONLY"];
     logger.logDestination = MPILogDestinationAPI;
     [logger info:source description:@"API ONLY"];
    */
    
    // setup logger at INFO level and to console and API
    logger.logLevel = MPILoggerLevelFatal;
    logger.logDestination = MPILogDestinationConsole;
}

- (void) createExpireNotification
{
    [self killExpireNotification];
    
    // if peers connected, setup kill switch
    if ([MPIGameManager instance].connectedPeers.count != 0)
    {
        // create notification that will get the user back into the app when the background process time is about to expire
        //NSTimeInterval msgTime = UIApplication.sharedApplication.backgroundTimeRemaining - gracePeriod;
        NSTimeInterval msgTime = 10.0f;
        
        UILocalNotification* n = [[UILocalNotification alloc] init];
        self.expireNotification = n;
        self.expireNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:msgTime];
        self.expireNotification.alertBody = @"Session is about to expire.";
        self.expireNotification.soundName = UILocalNotificationDefaultSoundName;
        self.expireNotification.applicationIconBadgeNumber = 1;
        
        [UIApplication.sharedApplication scheduleLocalNotification:self.expireNotification];
    }
}

- (void) killExpireNotification
{
    if (self.expireNotification != nil)
    {
        [UIApplication.sharedApplication cancelLocalNotification:self.expireNotification];
        self.expireNotification = nil;
    }
}
- (void) applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    self.endSessionTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                             {
                                 [[MPIGameManager instance] shutdown];
                                 [[UIApplication sharedApplication] endBackgroundTask:self.endSessionTaskId];
                                 self.endSessionTaskId = UIBackgroundTaskInvalid;
                             }];
    [self createExpireNotification];
}
- (void) applicationWillEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterBackground");
    self.endSessionTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                   {
                       [[MPIGameManager instance] shutdown];
                       [[UIApplication sharedApplication] endBackgroundTask:self.endSessionTaskId];
                       self.endSessionTaskId = UIBackgroundTaskInvalid;
                   }];
    [self createExpireNotification];
}

- (void) applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    [self killExpireNotification];
    if (self.endSessionTaskId != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.endSessionTaskId];
        self.endSessionTaskId = UIBackgroundTaskInvalid;
    }
    // NOTE: let the session state events handle disconnect/reconnection
    // this way if the app comes back into forground with active session
    // it isn't automatically disconnected
    // TODO: check connected peers? .. and restart previous services?
    //[[MPIGameManager instance] startup];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self killExpireNotification];
    [[MPIGameManager instance] shutdown]; // shutdown multi-peer
}

@end
