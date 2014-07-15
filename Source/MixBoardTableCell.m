//
//  MPIMixBoardTableCell.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "MixBoardTableCell.h"
#import "GameManager.h"

@interface MPIMixBoardTableCell()
@property float lastSentVolume;
@property float lastSentColor;
@end

@implementation MPIMixBoardTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        // setup record button states
        [_recordButton setTitle:@"Record" forState:UIControlStateNormal];
        [_recordButton setTitle:@"Stop" forState:UIControlStateSelected];
        // setup play here button states
        [_playHereButton setTitle:@"Play Here" forState:UIControlStateNormal];
        [_playHereButton setTitle:@"Stop Here" forState:UIControlStateSelected];
        // setup play there button states
        [_playThereButton setTitle:@"Play There" forState:UIControlStateNormal];
        [_playThereButton setTitle:@"Stop There" forState:UIControlStateSelected];

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)flashSwitchChanged:(id)sender {
    //NSLog(@"[%@] Flash switch changed: %hhd",_player.name, [_flashSwitch isOn]);
    NSNumber *val = [[NSNumber alloc] initWithInt:[_flashSwitch isOn] ? 1 : 0];
    
    [[MPIGameManager instance] requestFlashChange:_playerID value:val];
}

- (IBAction)colorSliderChanged:(id)sender {
    //NSLog(@"[%@] Color slider changed: %f", _player.name,_colorSlider.value);
    
    float diff = ABS(_colorSlider.value - _lastSentColor);
    if (diff < 0.05) {
        return;
    }
    
    _lastSentColor = _colorSlider.value;
    [[MPIGameManager instance] requestColorChange:_playerID value:[[NSNumber alloc] initWithFloat: _lastSentColor]];
}

- (IBAction)volumeSliderChanged:(id)sender {
    //NSLog(@"[%@] Volume slider changed: %f", _player.name,_soundSlider.value);
    
    float diff = ABS(_soundSlider.value - _lastSentVolume);
    if (diff < 0.05) {
        return;
    }
    
    _lastSentVolume = _soundSlider.value;
    [[MPIGameManager instance] requestSoundChange:_playerID value:[[NSNumber alloc] initWithFloat: _lastSentVolume]];
}

- (IBAction)playRecordingHere:(id)sender {
    if (_playHereButton.selected) {
        // stop local playback
        [[MPIGameManager instance] stopPlayRecordingFor:_playerID.displayName];
        
        // stop streaming
        [[MPIGameManager instance] stopStreamingRecordingFrom:_playerID.displayName];
        
        _playHereButton.selected = NO;
    } else {
        // play locally
        [[MPIGameManager instance] startPlayRecordingFor:_playerID.displayName];
        
        // and stream to associated peer
        [[MPIGameManager instance] startStreamingRecordingTo:_playerID fromPlayerName:_playerID.displayName];
        
        // remember state
        _playHereButton.selected = YES;
    }
}

- (IBAction)recordMic:(id)sender {
    if (_recordButton.selected) {
        [[MPIGameManager instance] stopRecordMicFor:_playerID.displayName withPeer:_playerID];
        _recordButton.selected = NO;
        _playThereButton.selected = YES;
        _playHereButton.selected = YES;
    } else {
        [[MPIGameManager instance] startRecordMicFor:_playerID.displayName];
        _recordButton.selected = YES;
    }
}

- (IBAction)playRecordingThere:(id)sender {
    
    if (_playThereButton.selected) {
        // stop remote playback
        [[MPIGameManager instance] stopPlayRecordingFor:_playerID.displayName onPeer:_playerID];
        
        // stop streaming
        //[[MPIGameManager instance] stopStreamingRecordingFrom:_playerID.displayName];
        
        _playThereButton.selected = NO;
    } else {
        // send message to start playing remotely
        [[MPIGameManager instance] startPlayRecordingFor:_playerID.displayName onPeer:_playerID];
        
        // and stream to associated peer
        //[[MPIGameManager instance] startStreamingRecordingTo:_playerID fromPlayerName:_playerID.displayName];
        
        // remember state
        _playThereButton.selected = YES;
    }
}


@end
