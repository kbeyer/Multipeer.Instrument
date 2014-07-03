//
//  MPIMotionManager.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/2/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

@import CoreMotion;

#import "MPIMotionManager.h"

static const float kMinChangeBeforeNotice = 0.2;

@interface MPIMotionManager ()
@property (nonatomic, retain) CMMotionManager *manager;
@property (nonatomic, retain) CMAttitude* referenceAttitude;
@property (readwrite) CMRotationRate referenceRotation;
@end

@implementation MPIMotionManager

- (id)init {
    
    self = [super init];
    if (self) {
        // initial configuration
        [self configure];
    }
    return self;
}

- (void)configure {
    // create single instance
    self.manager = [CMMotionManager new];
}

+ (MPIMotionManager *)instance
{
    static MPIMotionManager* sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MPIMotionManager alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark - Memory management

- (void)dealloc
{
    [_manager stopDeviceMotionUpdates];
    _manager = nil;
    _referenceAttitude = nil;
}

#pragma mark - start stop

- (void)start
{
    //check for gyroscope
    if([_manager isGyroAvailable])
    {
        // Start the gyroscope if it is not active already
        if([_manager isGyroActive] == NO)
        {
            // Update 2  times a second
            [_manager setGyroUpdateInterval:1.0f / 2.0f];
            
            // save reference attitude
            CMAttitude *attitude = _manager.deviceMotion.attitude;
            self.referenceAttitude = [attitude copy];
            self.referenceRotation = _manager.deviceMotion.rotationRate;
            
            // handle motion updates
            [_manager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
             {
                 if (error) { NSLog(@"Error on motion update. %@", error); return; }
                 
                 float dYaw = motion.attitude.yaw-_referenceAttitude.yaw;
                 float dPitch = motion.attitude.pitch-_referenceAttitude.pitch;
                 float dRoll = motion.attitude.roll-_referenceAttitude.roll;
                 
                 if (fabs(dYaw) > kMinChangeBeforeNotice ||
                     fabs(dPitch) > kMinChangeBeforeNotice ||
                     fabs(dRoll) > kMinChangeBeforeNotice ) {
                     
                     [_delegate attitudeChanged:dYaw
                                      pitch:dPitch
                                       roll:dRoll];
                 }
                 
                 // save new reference
                 self.referenceAttitude = [motion.attitude copy];
             }];
            
            
             // handle gyro
             [_manager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
             withHandler:^(CMGyroData *gyroData, NSError *error)
             {
             if (error) { NSLog(@"Error on Gyro update. %@", error); return; }
                 
                 if (error) { NSLog(@"Error on motion update. %@", error); return; }
                 
                 float dX = gyroData.rotationRate.x - _referenceRotation.x;
                 float dY = gyroData.rotationRate.y - _referenceRotation.y;
                 float dZ = gyroData.rotationRate.z - _referenceRotation.z;
                 
                 if (fabs(dX) > kMinChangeBeforeNotice ||
                     fabs(dY) > kMinChangeBeforeNotice ||
                     fabs(dZ) > kMinChangeBeforeNotice ) {
                     
                     [_delegate rotationChanged:dX
                                          y:dY
                                           z:dZ];
                 }
                 
                 // save new reference
                 self.referenceRotation = gyroData.rotationRate;
             }];
            
        }
    }
    else
    {
        NSLog(@"Gyroscope not Available!");
    }
}

- (void)stop
{
    [_manager stopDeviceMotionUpdates];
}

@end

