//
//  OKCloud.h
//  OKClient
//
//  Created by Louis Zell on 1/23/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKGUI.h"
#import "KGModal.h"
#import "OKBaseViewController.h"
#import "OKLeaderboardsListViewController.h"
#import "OKLoginView.h"


static OKBaseViewController *__okController = nil;
static UIWindow *__okWindow = nil;
static UIWindow *__cachedWindow = nil;
static OKBlock __okModalBlock = nil;
static UIView *__currentModal = nil;



@implementation OKGUI

+ (void)presentModal:(UIView*)view withClose:(OKBlock)handler
{
    if(__okModalBlock)
        __okModalBlock();
    
    KGModal *modal = [KGModal sharedInstance];
    [modal setTapOutsideToDismiss:NO];
    [modal setShowCloseButton:NO];
    [modal showWithContentView:view andAnimated:YES];
    __okModalBlock = handler;
    __currentModal = view;
}


+ (void)pushViewController:(OKViewController*)controller withClose:(OKBlock)handler
{
    if(!__okController) {
        __okController = [[OKBaseViewController alloc] initWithRootViewController:controller];
        __okWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [__okWindow setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [__okWindow setBackgroundColor:[UIColor clearColor]];
        [__okWindow setRootViewController:__okController];
        [__okWindow makeKeyAndVisible];
        [controller setOkparent:__okController];
    }else{
        [controller setOkparent:[__okController topViewController]];
        [__okController pushViewController:controller animated:YES];
    }
    [controller setOkBlock:handler];
}


+ (BOOL)callCloseBlocks:(NSArray*)controllers
{
    if(!controllers || [controllers count] == 0)
        return NO;
    
    for(OKViewController *controller in controllers) {
        if([controller isKindOfClass:[OKViewController class]] && [controller okBlock]) {
            controller.okBlock();
            controller.okBlock = nil;
        }
    }
    return YES;
}


#pragma mark - Public API

+ (void)showLeaderboardsListWithClose:(OKBlock)handler
{
    OKLeaderboardsListViewController *controller = [[OKLeaderboardsListViewController alloc] init];
    [OKGUI pushViewController:controller withClose:handler];
}


+ (void)showLeaderboardID:(NSInteger)lbID withClose:(OKBlock)handler
{
    OKLeaderboardsListViewController *controller = [[OKLeaderboardsListViewController alloc] init];
    [OKGUI pushViewController:controller withClose:handler];
}


+ (void)showProfileWithClose:(OKBlock)handler
{
    OKLeaderboardsListViewController *controller = [[OKLeaderboardsListViewController alloc] init];
    [OKGUI pushViewController:controller withClose:handler];
}


+ (void)showLoginModalWithClose:(OKBlock)handler
{
    OKLoginView *modal = [[OKLoginView alloc] init];
    [OKGUI presentModal:modal withClose:handler];
}


+ (void)popModal:(UIView*)modal
{
    if(__currentModal == modal)
        [OKGUI popModal];
}


+ (void)popModal
{
    if(__okModalBlock)
        __okModalBlock();
    
    [[KGModal sharedInstance] hide];
    __okModalBlock = nil;
    __currentModal = nil;
}


+ (void)popViewController
{
    if(__okController) {
        OKViewController *controller = (OKViewController*)[__okController popViewControllerAnimated:YES];
        if(![OKGUI callCloseBlocks:@[controller]])
            [OKGUI close];
    }
}


+ (void)popViewController:(OKViewController*)controller
{
    if(__okController) {
        NSArray *controllers = [__okController popToViewController:[controller okparent] animated:YES];
        if(![OKGUI callCloseBlocks:controllers])
            [OKGUI close];
    }
}


+ (void)close
{
    if(__okController) {
        NSArray *controllers = [__okController popToRootViewControllerAnimated:NO];
        [OKGUI callCloseBlocks:controllers];
        [__okWindow setRootViewController:nil];
        __okController = nil;
        __okWindow = nil;
        
        [__cachedWindow makeKeyAndVisible];
    }
}


@end
