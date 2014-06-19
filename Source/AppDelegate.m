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

@implementation MPIAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // configure MPIEventLogger
    [self setupEventLogger];
    
    
    
    // initial game launch
    [MPIGameManager instance];
    
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
    logger.logDestination = MPILogDestinationALL;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    
    //[[MPIPubNubManager pubnub] disconnect];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    
    // unsubscribe when in background
    //[[MPIPubNubManager pubnub] disconnect];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // reconnect
    //[[MPIPubNubManager pubnub] connect];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
