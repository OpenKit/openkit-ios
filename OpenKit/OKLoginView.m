//
//  OKLoginView.m
//  OKClient
//
//  Created by Suneet Shah on 2/4/13.
//  Copyright (c) 2013 Suneet Shah. All rights reserved.
//

#import "OKLoginView.h"
#import "KGModal.h"
#import "OKBaseLoginViewController.h"

@interface OKLoginView()<OKLoginViewDelegate>
{
    OKLoginViewCompletionHandler loginDialogCompletionHandler;
}

@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) OKBaseLoginViewController *baseViewController;

@end

@implementation OKLoginView

@synthesize loginView, baseViewController;

-(id)init
{
    return [self initWithLoginString:@"Create an account to access leaderboards and resume game progress from any device."];
}

-(id)initWithLoginString:(NSString *)loginString
{
    self = [super init];
    
    if(self) {
        baseViewController = [[OKBaseLoginViewController alloc] initWithLoginString:loginString];
    }
    
    return self;
}

-(void)show
{
    //Show the base view controller on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIApplication sharedApplication] keyWindow] addSubview:baseViewController.view];
    });
    
    [baseViewController setDelegate:self];
    [baseViewController showLoginModalView];
}

-(void)showWithCompletionHandler:(OKLoginViewCompletionHandler)block
{
    loginDialogCompletionHandler = block;
    [self show];
}

-(void)dismiss
{
    //Remove the base view controller on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [baseViewController.view removeFromSuperview];
    });
    
    [baseViewController setDelegate:nil];
    if(loginDialogCompletionHandler != nil) {
        loginDialogCompletionHandler();
        loginDialogCompletionHandler = nil;
    }
    
}





@end
