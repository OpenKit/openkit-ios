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

@property (nonatomic, strong) UIWindow *baseWindow;
@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) OKBaseLoginViewController *baseViewController;

@end

@implementation OKLoginView

@synthesize loginView, baseWindow, baseViewController;

-(id)init
{
    self = [super init];
    if(self)
    {
        //Create the base window
        baseWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        baseWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        baseWindow.opaque = NO;
        
        baseViewController = [[OKBaseLoginViewController alloc] init];
        
        [baseWindow setRootViewController:baseViewController];
        //[baseWindow setWindowLevel:UIWindowLevelAlert];
    }
    return self;
}

-(void)show
{
    //Show the base window on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.baseWindow makeKeyAndVisible];
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
    //Show the base window on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [baseWindow removeFromSuperview];
    });
    
    [baseViewController setDelegate:nil];
    if(loginDialogCompletionHandler != nil) {
        loginDialogCompletionHandler();
        loginDialogCompletionHandler = nil;
    }
    
}





@end
