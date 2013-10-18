//
//  OKDashboard.m
//  OpenKit
//
//  Created by Suneet Shah on 10/17/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKDashboard.h"
#import "OKLeaderboardsViewController.h"
#import "OKChatViewController.h"

@implementation OKDashboard

+(UIViewController*)OKDashboardViewController
{
    OKLeaderboardsViewController *leaderboards = [[OKLeaderboardsViewController alloc] init];
    OKChatViewController *chat = [[OKChatViewController alloc] init];
    
    NSArray *viewControllers = [NSArray arrayWithObjects:leaderboards, chat, nil];
    
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    [tabBar setViewControllers:viewControllers];
    
    return tabBar;
}

@end
