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
    
    
    UITabBarItem *leaderboardsItem = [[UITabBarItem alloc] initWithTitle:@"Leaderboards" image:[UIImage imageNamed:@"leaderboards.png"] selectedImage:[UIImage imageNamed:@"leaderboards_active.png"]];
    [leaderboards setTabBarItem:leaderboardsItem];
    
    UITabBarItem *chatItem = [[UITabBarItem alloc] initWithTitle:@"Chat" image:[UIImage imageNamed:@"chat.png"] selectedImage:[UIImage imageNamed:@"chat_active.png"]];
    [chat setTabBarItem:chatItem];
    
    NSArray *viewControllers = [NSArray arrayWithObjects:leaderboards, chat, nil];
    
    UITabBarController *tabBar = [[UITabBarController alloc] init];
    [tabBar setViewControllers:viewControllers];
    
    return tabBar;
}

@end
