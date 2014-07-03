//
//  MPIMotionManager.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 7/2/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MPIMotionManagerDelegate;

@interface MPIMotionManager : NSObject

+ (MPIMotionManager*)instance;

@property (nonatomic,weak) id<MPIMotionManagerDelegate> delegate;

-(void)start;
-(void)stop;

@end

// Delegate methods for motion manager
@protocol MPIMotionManagerDelegate <NSObject>

- (void)attitudeChanged:(float)yaw pitch:(float)pitch roll:(float)roll;
- (void)rotationChanged:(float)x y:(float)y z:(float)z;

@end