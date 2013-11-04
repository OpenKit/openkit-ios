//
//  OKViewController.m
//  SampleApp
//
//  Created by Suneet Shah on 12/26/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
#import "OKDBScore.h"
#import "OKGUI.h"
#import "OKViewController.h"
#import "ScoreSubmitterVC.h"
#import "OKGameCenterPlugin.h"


@implementation ViewController

- (id)init
{
    self = [super initWithNibName:@"ViewController" bundle:nil];
    self.navigationItem.title = @"OpenKit Sample App";
    return self;
}


-(void)updateUIforOKUser
{
    OKLocalUser *user = [OKLocalUser currentUser];
    if (user) {
        [self.loginButton setHidden:YES];
        [self.logoutButton setHidden:NO];
        
        [self.profileImageView setUser:user];
        [self.userNickLabel setHidden:NO];
        [self.userNickLabel setText:[user name]];
    } else {
        [self.loginButton setHidden:NO];
        [self.logoutButton setHidden:YES];
        [self.profileImageView setUser:nil];
        [self.userNickLabel setHidden:YES];
        
    }
}


-(IBAction)launchGameCenter:(id)sender
{
    [[OKGameCenterPlugin sharedInstance] openSessionWithViewController:self completion:^(BOOL login, NSError *error) {
        NSLog(@"Open Game Center");
    }];
}

-(IBAction)logoutOfOpenKit:(id)sender
{
    [[OKManager sharedManager] logoutCurrentUser];
    [self updateUIforOKUser];
}


-(IBAction)loginToOpenKit:(id)sender
{
    [OKGUI showLoginModalWithClose:^{
        NSLog(@"Closed modal");
        [self updateUIforOKUser];
    }];
}


-(IBAction)viewLeaderboards:(id)sender
{
    [OKGUI showLeaderboardsListWithClose:^{
        NSLog(@"Closed leaderboards");
    }];
}


-(IBAction)submitScore:(id)sender
{
    ScoreSubmitterVC *scoreSubmitter = [[ScoreSubmitterVC alloc] initWithNibName:@"ScoreSubmitterVC" bundle:nil];
    scoreSubmitter.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:scoreSubmitter animated:YES completion:nil];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUIforOKUser];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
