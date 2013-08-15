//
//  OKLeaderboardSetupVC.m
//  OpenKit
//
//  Created by Todd Hamilton on Aug/14/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLeaderboardSetupVC.h"
#import "OpenKit.h"

@interface OKLeaderboardSetupVC ()

@end

@implementation OKLeaderboardSetupVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(IBAction)closeSetup:(id)sender
{
  [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
