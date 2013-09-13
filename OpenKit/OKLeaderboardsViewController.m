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
#import "OKColors.h"

@interface OKLeaderboardsViewController ()

@end

@implementation OKLeaderboardsViewController

@synthesize showLandscapeOnly;

- (id)init {
    return [self initWithDefaultLeaderboardID:0];
}

-(id)initWithDefaultLeaderboardID:(int)leaderboardID
{
    OKLeaderboardsListViewController *list = [[OKLeaderboardsListViewController alloc] initWithDefaultLeaderboardID:leaderboardID];
    
    self = [super initWithRootViewController:list];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
//        [[self navigationBar] setBarStyle:UIBarStyleBlack];
//        [[self navigationBar] setTintColor:[OKColors navbarTintColor]];
//        [[self navigationBar] setTitleTextAttributes:
//         [NSDictionary dictionaryWithObjectsAndKeys:
//          [OKColors navbarTextColor], UITextAttributeTextColor,
//          [UIColor whiteColor], UITextAttributeTextShadowColor,
//          [NSValue valueWithUIOffset:UIOffsetMake(0, 1)], UITextAttributeTextShadowOffset,
//          nil]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:OKLeaderboardsViewWillAppear
                                                        object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:OKLeaderboardsViewWillDisappear
                                                        object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:OKLeaderboardsViewDidAppear
                                                        object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:OKLeaderboardsViewDidDisappear
                                                        object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    if(showLandscapeOnly)
        return UIInterfaceOrientationMaskLandscape;
    else
        return UIInterfaceOrientationMaskAllButUpsideDown;
}

 


@end
