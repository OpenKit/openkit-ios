//
//  OKLoginViewController.m
//  OpenKit
//
//  Created by Suneet Shah on 9/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLoginViewController.h"

@interface OKLoginViewController ()

@end

@implementation OKLoginViewController
@synthesize  popupView, window;

- (id)init
{
    self = [super init];
    if(self) {
        //custom init
    }
    return self;
}

-(void)showPopup{
    NSLog(@"Show popup");
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"ViewDidAppear in LoginViewController");
}

-(void)loadView
{
    NSLog(@"loadView");
    popupView = [[OKLoginPopupView alloc] init];
    [popupView setDelegate:self];
    [self setView:popupView];
    return;
}

-(void)finishButtonPressed
{
    NSLog(@"Finish button pressed");
    [self setView:nil];
    [self setWindow:nil];
}
-(void)fbButtonPressed
{
    NSLog(@"fb button pressed");
}
-(void)gcButtonPressed
{
    NSLog(@"gc button pressed");
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
