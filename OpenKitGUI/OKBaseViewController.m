//
//  OKLeaderboardsViewController.m
//  OKClient
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKBaseViewController.h"


@implementation OKBaseViewController

- (id)initWithRootViewController:(UIViewController*)controller
{    
    self = [super initWithRootViewController:controller];
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


- (NSUInteger)supportedInterfaceOrientations
{
    if(_showLandscapeOnly)
        return UIInterfaceOrientationMaskLandscape;
    else
        return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
