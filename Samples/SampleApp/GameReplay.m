//
//  ScoreSubmitterVC.m
//  SampleApp
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "GameReplay.h"
#import "OpenKit.h"
#import "ActionSheetStringPicker.h"

@interface GameReplayViewController ()
{
    OKGame * _game;
    OKReplay * _replay;
}
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *hero;
@property (weak, nonatomic) IBOutlet UIView *enemy;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@end

@implementation GameReplayViewController

-(id)initWithGame:(OKGame*)game
{
    self = [super init];
    if (self) {
        _game = game;
        _replay = [game replay];
    }
    return self;
}

//[_replay setReplayHandler:^(double progress, double step, id data) {
//    
//    if(data[@"hero"]) {
//        float x = [data[@"hero"][@"x"] floatValue];
//        float y = [data[@"hero"][@"y"] floatValue];
//        
//        [_hero setCenter:CGPointMake(x, y)];
//    }
//    
//    if(data[@"enemy"]) {
//        float x = [data[@"enemy"][@"x"] floatValue];
//        float y = [data[@"enemy"][@"y"] floatValue];
//        
//        [_enemy setCenter:CGPointMake(x, y)];
//    }
//    
//    [_progressBar setProgress:progress animated:YES];
//}];

-(void)viewDidAppear:(BOOL)animated
{
    [_timeLabel setText:[NSString stringWithFormat:@"Playing time: %.2f seconds", [_game playingTime]]];
    
    [self replay:nil];
}




- (IBAction)changeSpeed:(UISlider*)sender {
    [_replay setSpeed:[sender value]];
}


- (IBAction)replay:(id)sender
{
    [_replay setProgress:0];
    [_replay replayWithBlock:^(double progress, double step, id data) {
#if 0
        [UIView animateWithDuration:step animations:^{ 
            float x = [data[@"x"] floatValue];
            float y = [data[@"y"] floatValue];
            
            [_hero setCenter:CGPointMake(x, y)];
            [_progressBar setProgress:progress animated:NO];

        } completion:nil];
#else
        float x = [data[@"x"] floatValue];
        float y = [data[@"y"] floatValue];
        
        [_hero setCenter:CGPointMake(x, y)];
        [_progressBar setProgress:progress animated:NO];
        
#endif
        
    } completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
