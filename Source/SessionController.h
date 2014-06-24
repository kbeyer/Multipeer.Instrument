//
//  MPISessionControlelr.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol MPISessionControllerDelegate;

/*!
 @class MPISessionController
 @abstract
 A SessionController creates the MCSession that peers will be invited/join
 into, as well as creating service advertisers and browsers.
 
 MCSessionDelegate calls occur on a private operation queue. If your app
 needs to perform an action on a particular run loop or operation queue,
 its delegate method should explicitly dispatch or schedule that work
 */
@interface MPISessionController : NSObject <MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>

@property (nonatomic, weak) id<MPISessionControllerDelegate> delegate;

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSArray *connectingPeers;
@property (nonatomic, readonly) NSArray *connectedPeers;
@property (nonatomic, readonly) NSArray *disconnectedPeers;

// Helper method for human readable printing of MCSessionState. This state is per peer.
- (NSString *)stringForPeerConnectionState:(MCSessionState)state;

// the peer used as reference time server
@property (strong, nonatomic) MCPeerID* timeServerPeerID;

// Helper method for sending messages to peers
- (void)sendTimestamp:(MCPeerID*)peer;
- (void)sendTimestamp:(NSNumber*)val toPeer:(MCPeerID*)peer;
- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeer:(MCPeerID*)peer;
- (void)sendMessage:(NSString*)type value:(NSNumber*)val toPeers:(NSArray*)peers;

// advertiser and browser controller
- (void)startAdvertising;
- (void)stopAdvertising;
- (void)startBrowsing;
- (void)stopBrowsing;

// stop all multi-peer related sessions
- (void)startup;
- (void)shutdown;

@end

// Delegate methods for SessionController
@protocol MPISessionControllerDelegate <NSObject>

// Session changed state - connecting, connected and disconnected peers changed
- (void)sessionDidChangeState;

@end

