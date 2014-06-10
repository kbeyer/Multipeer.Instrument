//
//  MPIMixBoardViewController.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MixBoardViewController.h"
#import "MixBoardTableCell.h"
#import "GameManager.h"
#import "Player.h"

#define kFirechatNS @"https://sizzling-fire-5489.firebaseio.com/"


#import "UIActionSheet+Blocks.h"

@interface MPIMixBoardViewController ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end


@implementation MPIMixBoardViewController


- (BOOL)prefersStatusBarHidden{ return YES; }


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    
    
    // configure changes to listen to
    
    // listen for players change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerListChanged) name:@"playerListChanged" object:nil];
    // listen for audio change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged) name:@"volumeChanged" object:nil];
    // listen for color change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorChanged) name:@"colorChanged" object:nil];
    
    // configure audio player
    [self configureAudio];
    
    // set name
    _nameInput.text = [MPIGameManager instance].sessionController.displayName;
    
}

- (void)configureAudio
{
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle]
                                         pathForResource:@"Organ Run"
                                         ofType:@"m4a"]];
    
    NSError *error;
    _audioPlayer = [[AVAudioPlayer alloc]
                    initWithContentsOfURL:url
                    error:&error];
    if (error)
    {
        NSLog(@"Error in audioPlayer: %@",
              [error localizedDescription]);
    } else {
        _audioPlayer.delegate = self;
        [_audioPlayer prepareToPlay];
    }
}

- (void)volumeChanged{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_audioPlayer != nil)
        {
            
            _audioPlayer.volume = [[[MPIGameManager instance] volume] floatValue];
            
            if (!_audioPlayer.isPlaying) {
                [_audioPlayer play];
            }
        }
    });
}
- (void)colorChanged{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.alpha = [[[MPIGameManager instance] color] floatValue];
    });
}

- (void)playerListChanged
{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        [_participantTableView reloadData];
    });
}

#pragma mark - Memory management

- (void)dealloc
{
    // Nil out delegates
    _audioPlayer.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //return [MPIPubNubManager pubnub].currentGame.players.count;
    return [MPIGameManager instance].sessionController.connectedPeers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlayerCell";
    MPIMixBoardTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSArray *peers = [MPIGameManager instance].sessionController.connectedPeers;
    NSInteger peerIndex = indexPath.row;
    if ((peers.count > 0) && (peerIndex < peers.count))
    {
        MCPeerID *peerID = [peers objectAtIndex:peerIndex];
        
        if (peerID)
        {
            cell.playerID = peerID;
            cell.nameLabel.text = peerID.displayName;
        }
    }
    
    // get player for cell
    //MPIPlayer* player = [MPIPubNubManager pubnub].currentGame.players[indexPath.row];
    
    // Configure the cell...
    //cell.player = player;
    //cell.nameLabel.text = player.name;
    
    return cell;
}

#pragma mark - Touch ACTIONS

- (IBAction)discoverClicked:(id)sender {
    //[self.sessionController startServices];
}

- (IBAction)advertiseChanged:(id)sender {
    UISwitch* advertiseSwitch = (UISwitch*)sender;
    
    if (advertiseSwitch.isOn) {
        //[self.sessionController  startAdvertisingPeer];
    } else {
        //[self.sessionController  stopAdvertisingPeer];
    }

}
@end
