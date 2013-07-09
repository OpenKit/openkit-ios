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

- (id)init
{
    OKLeaderboardsListViewController *list = [[OKLeaderboardsListViewController alloc] init];
    
    self = [super initWithRootViewController:list];
    if (self) {
        [[self navigationBar] setBarStyle:UIBarStyleBlack];
        [[self navigationBar] setTintColor:[OKColors navbarTintColor]];
        [[self navigationBar] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [OKColors navbarTextColor], UITextAttributeTextColor,
          [UIColor whiteColor], UITextAttributeTextShadowColor,
          [NSValue valueWithUIOffset:UIOffsetMake(0, 1)], UITextAttributeTextShadowOffset,
          nil]];
        
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
