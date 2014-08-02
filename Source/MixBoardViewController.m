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


#import "UIActionSheet+Blocks.h"

@interface MPIMixBoardViewController ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (weak, nonatomic) IBOutlet UIImageView *albumImage;
@property (weak, nonatomic) IBOutlet UILabel *songTitle;
@property (weak, nonatomic) IBOutlet UILabel *songArtist;

@property (strong, nonatomic) MPMediaItem *song;

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
    // listen for audio input stream
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInChanged) name:@"audioInChanged" object:nil];
    // listen for song changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioInSongChanged) name:@"songChanged" object:nil];
    
    // configure audio player
    [self configureAudio];
    
    // set name
    _nameInput.text = [MPIGameManager instance].sessionController.displayName;
    
    // timer for updating clock
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
    
}

- (void)timerTick:(NSTimer *)timer {
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"hh:mm:ss.SSS";
    }
    _timeLabel.text = [dateFormatter stringFromDate:[NSDate date]];
    _timeWithOffsetLabel.text = [dateFormatter stringFromDate:[MPIGameManager instance].currentTime];
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

- (void)audioInChanged
{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"SONG SELECTION DISABLED");
        //[[[MPIGameManager instance] audioInStream] start];
    });
}

- (void)audioInSongChanged
{
    // Ensure UI updates occur on the main queue.
    dispatch_async(dispatch_get_main_queue(), ^{
        _songArtist.text = [MPIGameManager instance].lastSongMessage.artist;
        _songTitle.text = [MPIGameManager instance].lastSongMessage.title;
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
    return [MPIGameManager instance].connectedPeers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PlayerCell";
    MPIMixBoardTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSArray *peers = [[MPIGameManager instance].connectedPeers array];
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

#pragma mark - Media Picker delegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSLog(@"Song selected.");
    
    if ([mediaItemCollection.items[0] valueForProperty:MPMediaItemPropertyAssetURL] == nil) {
        NSLog(@"Song is protected.");
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // check if already streaming
    //if (self.outputStreamer) return;
    
    self.song = [mediaItemCollection.items[0] copy];
    
    MPISongInfoMessage *info = [[MPISongInfoMessage alloc] init];
    info.title = [self.song valueForProperty:MPMediaItemPropertyTitle] ? [self.song valueForProperty:MPMediaItemPropertyTitle] : @"";
    info.artist = [self.song valueForProperty:MPMediaItemPropertyArtist] ? [self.song valueForProperty:MPMediaItemPropertyArtist] : @"";
    
    MPMediaItemArtwork *artwork = [self.song valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *image = [artwork imageWithSize:self.albumImage.frame.size];
    if (image) {
        //info.artwork = image;
        self.albumImage.image = image;
    }
    else {
        self.albumImage.image = nil;
    }
    
    self.songTitle.text = info.title;
    self.songArtist.text = info.artist;
    
    // TODO: refactor type into MPISongInfoMessage object
    info.type = @"6";
    info.createdAt = [[MPIEventLogger sharedInstance] timeWithOffset:[NSDate date]];
    NSArray *peers = [[MPIGameManager instance].connectedPeers array];
    
    // TODO: send song info and stream to all peers
    if (peers.count) {
        [[MPIGameManager instance].sessionController sendMessage:info toPeer:peers[0]];
        
        NSLog(@"FILE STREAMING DISABLED");
        /*
        self.outputStreamer = [[TDAudioOutputStreamer alloc] initWithOutputStream:[[MPIGameManager instance].sessionController outputStreamForPeer:peers[0]]];
        
        [self.outputStreamer streamAudioFromSong:mediaItemCollection.items[0]];
        //[self.outputStreamer streamAudioFromURL:[self.song valueForProperty:MPMediaItemPropertyAssetURL]];
        [self.outputStreamer start];
         */
    }
    
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    NSLog(@"Cancelled media picker.");
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Touch ACTIONS

- (IBAction)songsClicked:(id)sender {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    picker.allowsPickingMultipleItems = NO;
    picker.prompt = @"Select song to stream.";
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)advertiseChanged:(id)sender {
    UISwitch* advertiseSwitch = (UISwitch*)sender;
    
    if (advertiseSwitch.isOn) {
        [[MPIGameManager instance].sessionController startAdvertising];
    } else {
        [[MPIGameManager instance].sessionController stopAdvertising];
    }

}

- (IBAction)browseChanged:(id)sender {
    UISwitch* advertiseSwitch = (UISwitch*)sender;
    
    if (advertiseSwitch.isOn) {
        [[MPIGameManager instance].sessionController startBrowsing];
    } else {
        [[MPIGameManager instance].sessionController stopBrowsing];
    }
}

- (IBAction)micChanged:(id)sender {
    UISwitch* micSwitch = (UISwitch*)sender;
    
    if (micSwitch.isOn) {
        NSArray *peers = [[MPIGameManager instance].connectedPeers array];
        NSOutputStream *outputStream = nil;
        
        //
        // TODO: send song info and stream to all peers
        //
        if (peers.count) {
            outputStream = [[MPIGameManager instance].sessionController outputStreamForPeer:peers[0] withName:@"mic"];
        }
        [[MPIGameManager instance] startEcho:outputStream];
    } else {
        [[MPIGameManager instance] stopEcho];
    }
}

- (IBAction)logToApiChanged:(id)sender {
    UISwitch* apiSwitch = (UISwitch*)sender;
    if (apiSwitch.isOn) {
        [MPIEventLogger sharedInstance].logDestination = MPILogDestinationALL;
    } else {
        [MPIEventLogger sharedInstance].logDestination = MPILogDestinationConsole;
    }
}

- (IBAction)reverbChanged:(id)sender {
    [[MPIGameManager instance] changeReverb:((UISwitch*)sender).isOn];
}

- (IBAction)gainChanged:(id)sender {
    [[MPIGameManager instance] changeRecordingGain:((UISlider*)sender).value];
}

- (IBAction)limiterChanged:(id)sender {
    [[MPIGameManager instance] changeLimiter:((UISwitch*)sender).isOn];
}

- (IBAction)expanderChanged:(id)sender {
    [[MPIGameManager instance] changeExpander:((UISwitch*)sender).isOn];
}
@end
