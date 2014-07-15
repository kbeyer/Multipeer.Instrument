//
//  MPIMixBoardTableCell.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MPIMixBoardTableCell : UITableViewCell

@property (strong, nonatomic) MCPeerID *playerID;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UISlider *soundSlider;
@property (weak, nonatomic) IBOutlet UISlider *colorSlider;
@property (weak, nonatomic) IBOutlet UISwitch *flashSwitch;
@property (weak, nonatomic) IBOutlet UIButton *playHereButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *playThereButton;
- (IBAction)flashSwitchChanged:(id)sender;
- (IBAction)colorSliderChanged:(id)sender;
- (IBAction)volumeSliderChanged:(id)sender;
- (IBAction)playRecordingHere:(id)sender;
- (IBAction)recordMic:(id)sender;
- (IBAction)playRecordingThere:(id)sender;

@end
