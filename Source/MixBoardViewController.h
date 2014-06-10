//
//  MPIMixBoardViewController.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MPIMixBoardViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *participantTableView;
@property (weak, nonatomic) IBOutlet UITextField *nameInput;
- (IBAction)discoverClicked:(id)sender;
- (IBAction)advertiseChanged:(id)sender;


@end