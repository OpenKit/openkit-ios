//
//  ViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/2/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)signIn{
  SignInViewController *signInView = [[SignInViewController alloc] initWithNibName:@"SignInViewController" bundle:[NSBundle mainBundle]];
  signInView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:signInView animated:YES completion:nil];
}

- (IBAction)nick{
  NickViewController *nickView = [[NickViewController alloc] initWithNibName:@"NickViewController" bundle:[NSBundle mainBundle]];
  nickView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:nickView animated:YES completion:nil];
}

- (IBAction)leaderboards{
  LeaderboardsViewController *leaderboardsView = [[LeaderboardsViewController alloc] initWithNibName:@"LeaderboardsViewController" bundle:[NSBundle mainBundle]];
  leaderboardsView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:leaderboardsView animated:YES completion:nil];
}

- (IBAction)leaderboard{
  LeaderboardViewController *leaderboardView = [[LeaderboardViewController alloc] initWithNibName:@"LeaderboardViewController" bundle:[NSBundle mainBundle]];
  leaderboardView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:leaderboardView animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
