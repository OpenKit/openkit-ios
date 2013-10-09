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

-(id)init
{
    return [self initWithLoginString:@"More Friends, More Fun!"];
}


-(id)initWithLoginString:(NSString *)loginString
{
    self = [super init];
    
    if(self) {
        _baseViewController = [[OKBaseLoginViewController alloc] initWithLoginString:loginString];
    }
    
    return self;
}


-(void)show
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    window.backgroundColor = [UIColor clearColor];
    
    [_baseViewController setDelegate:self];
    
    [_baseViewController setWindow:window];
    
    window = nil;
    
    [_baseViewController.window setRootViewController:_baseViewController];
    [_baseViewController.window makeKeyAndVisible];
    [_baseViewController showLoginModalView];
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
        [_baseViewController.view removeFromSuperview];
    });
    
    [_baseViewController setDelegate:nil];
    if(loginDialogCompletionHandler != nil) {
        loginDialogCompletionHandler();
        loginDialogCompletionHandler = nil;
    }
    
}

@end
