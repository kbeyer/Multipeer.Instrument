//
//  MPIMixBoardViewController.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

@import UIKit;
@import MediaPlayer;
@import AVFoundation;

@interface MPIMixBoardViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, MPMediaPickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *participantTableView;
@property (weak, nonatomic) IBOutlet UITextField *nameInput;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeWithOffsetLabel;
- (IBAction)songsClicked:(id)sender;
- (IBAction)advertiseChanged:(id)sender;
- (IBAction)browseChanged:(id)sender;


@end