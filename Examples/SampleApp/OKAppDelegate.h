//
//  OKAppDelegate.h
//  SampleApp
//
//  Created by Suneet Shah on 12/26/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const OK_FBSessionStateChangedNotification;
@class OKViewController;


@interface OKAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) OKViewController *viewController;

@end
