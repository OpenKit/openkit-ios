//
//  OKAppDelegate.h
//  SampleApp
//
//  Created by Suneet Shah on 12/26/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenKit.h"

@class ViewController;


@interface OKAppDelegate : UIResponder <UIApplicationDelegate, OKManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;

@end
