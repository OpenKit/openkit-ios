//
//  OKCloud.h
//  OKClient
//
//  Created by Louis Zell on 1/23/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKBaseViewController.h"
#import "UIImageView+Openkit.h"
#import "ActionSheetStringPicker.h"


@interface OKGUI : NSObject

+ (void)presentModal:(UIView*)view withClose:(OKBlock)handler;
+ (void)popModal;
+ (void)popModal:(UIView*)modal;

+ (void)showLeaderboardsListWithClose:(OKBlock)handler;
+ (void)showLeaderboardID:(NSInteger)lbID withClose:(OKBlock)handler;
+ (void)showProfileWithClose:(OKBlock)handler;
+ (void)showLoginModalWithClose:(OKBlock)handler;

+ (void)popViewController;
+ (void)popViewController:(OKViewController*)controller;
+ (void)close;

@end
