//
//  OKLeaderboardsViewController.m
//  OKClient
//
//  Created by Suneet Shah on 1/10/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLeaderboardsViewController.h"
#import "OKLeaderboardViewController.h"
#import "OKLeaderboardsListViewController.h"
#import "OKHelper.h"

@interface OKLeaderboardsViewController ()

@end

@implementation OKLeaderboardsViewController

- (id)init
{
    OKLeaderboardsListViewController *list = [[OKLeaderboardsListViewController alloc] init];
    
    self = [super initWithRootViewController:list];
    if (self) {
        [[self navigationBar] setBarStyle:UIBarStyleDefault];
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
