//
//  OKCloud.h
//  OKClient
//
//  Created by Louis Zell on 1/23/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KGModal.h"
#import "OKGUI.h"
#import "OKBaseViewController.h"
#import "OKLeaderboardsListViewController.h"
#import "OKSocialLeaderboardViewController.h"
#import "OKLoginView.h"


@interface OKGUI ()
{
    OKBlock _modalBlock;
    OKBaseViewController *_navController;
    UIWindow *_window;
    UIWindow *_cachedWindow;
    UIView *_currentModal;
}
@end


@implementation OKGUI

+ (id)sharedManager
{
    static dispatch_once_t pred;
    static OKGUI *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKGUI alloc] init];
    });
    return sharedInstance;
}


- (id)init
{
    self = [super init];
    if (self) {
        _navController = nil;
        _window = nil;
        _cachedWindow = nil;
        _modalBlock = nil;
        _currentModal = nil;
    }
    return self;
}

- (void)presentModal:(UIView*)view withClose:(OKBlock)handler
{
    if(_modalBlock)
        _modalBlock();
    
    KGModal *modal = [KGModal sharedInstance];
    [modal setTapOutsideToDismiss:NO];
    [modal setShowCloseButton:NO];
    [modal showWithContentView:view andAnimated:YES];
    _modalBlock = handler;
    _currentModal = view;
}


- (void)pushViewController:(OKViewController*)controller withClose:(OKBlock)handler
{
    if(!_navController) {
        _cachedWindow = [[[UIApplication sharedApplication] delegate] window];
        _navController = [[OKBaseViewController alloc] initWithRootViewController:controller];
        _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [_window setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [_window setBackgroundColor:[UIColor clearColor]];
        [_window setRootViewController:_navController];
        [_window makeKeyAndVisible];
        [controller setOkparent:_navController];
        
        
        // Fade in animation
        [[_navController view] setOpaque:NO];
        [[_navController view] setAlpha:0];
        [[_navController view] setUserInteractionEnabled:NO];
        [UIView animateWithDuration:0.2f
                         animations:^
        { 
            [[_navController view] setAlpha:1];
        }
                         completion:^(BOOL finished)
        {
            [[_navController view] setOpaque:YES];
            [[_navController view] setAlpha:1];
            [[_navController view] setUserInteractionEnabled:YES];
        }];
        
        if(_delegate && [_delegate respondsToSelector:@selector(openkitManagerWillShowDashboard:)])
            [_delegate openkitManagerWillShowDashboard:self];

    }else{
        [controller setOkparent:[_navController topViewController]];
        [_navController pushViewController:controller animated:YES];
    }
    [controller setOkBlock:handler];
}


- (BOOL)canPop:(OKViewController*)controller
{
    if(!_navController)
        return NO;

    if(controller)
        return ([[_navController viewControllers] indexOfObject:controller] > 0);
    else
        return ([[_navController viewControllers] count] > 1);
}


- (void)callCloseBlocks:(NSArray*)controllers
{
    if(controllers && [controllers count] > 0) {
        for(OKViewController *controller in controllers) {
            if([controller isKindOfClass:[OKViewController class]] && controller.okBlock) {
                controller.okBlock();
                controller.okBlock = nil;
            }
        }
    }
}


#pragma mark - Public API

- (void)popModal:(UIView*)modal
{
    if(_currentModal == modal)
        [self popModal];
}


- (void)popModal
{
    if(_modalBlock)
        _modalBlock();
    
    [[KGModal sharedInstance] hide];
    _modalBlock = nil;
    _currentModal = nil;
}


- (void)popViewController
{
    if([self canPop:nil]) {
        OKViewController *controller = (OKViewController*)[_navController popViewControllerAnimated:YES];
        [self callCloseBlocks:@[controller]];
    }else
        [self close];
}


- (void)popViewController:(OKViewController*)controller
{
    if(controller) {
        if([self canPop:controller]) {
            NSArray *controllers = [_navController popToViewController:[controller okparent] animated:YES];
            [self callCloseBlocks:controllers];
        }else
            [self close];
    }
}


- (void)close
{
    if(_navController) {
        [self callCloseBlocks:[_navController viewControllers]];
        
        
        // Fade out animation
        [[_navController view] setUserInteractionEnabled:NO];
        [[_navController view] setOpaque:NO];
        [UIView animateWithDuration:0.2f
                         animations:^
         { 
             [[_navController view] setAlpha:0];
         }
                         completion:^(BOOL finished)
         {
             [_navController popToRootViewControllerAnimated:NO];
             [_window setRootViewController:nil];
             _navController = nil;
             _window = nil;
             
             [_cachedWindow makeKeyAndVisible];
         }];
        
        if(_delegate && [_delegate respondsToSelector:@selector(openkitManagerWillHideDashboard:)])
            [_delegate openkitManagerWillHideDashboard:self];
    }
}


+ (void)showLeaderboardsListWithClose:(OKBlock)handler
{
    OKLeaderboardsListViewController *controller = [[OKLeaderboardsListViewController alloc] init];
    [[OKGUI sharedManager] pushViewController:controller withClose:handler];
}


+ (void)showLeaderboardID:(NSInteger)lbID withClose:(OKBlock)handler
{
    OKSocialLeaderboardViewController *controller = [[OKSocialLeaderboardViewController alloc] initWithLeaderboardID:lbID];
    [[OKGUI sharedManager] pushViewController:controller withClose:handler];
}


+ (void)showProfileWithClose:(OKBlock)handler
{
    OKLeaderboardsListViewController *controller = [[OKLeaderboardsListViewController alloc] init];
    [[OKGUI sharedManager] pushViewController:controller withClose:handler];
}


+ (void)showLoginModalWithClose:(OKBlock)handler
{
    OKLoginView *modal = [OKLoginView new];
    [[OKGUI sharedManager] presentModal:modal withClose:handler];
}

@end
