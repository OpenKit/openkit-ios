//
//  OKSocialLeaderboardViewController.m
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSocialLeaderboardViewController.h"

@interface OKSocialLeaderboardViewController ()

@end

@implementation OKSocialLeaderboardViewController

@synthesize leaderboard, tableView, moreBtn, spinner, socialScores, globalScores;

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard
{
    self = [super initWithNibName:@"OKLeaderboardViewController" bundle:nil];
    if (self) {
        leaderboard = aLeaderboard;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
