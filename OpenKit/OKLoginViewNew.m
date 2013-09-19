//
//  OKLoginViewNew.m
//  OpenKit
//
//  Created by Suneet Shah on 9/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLoginViewNew.h"
#import "OKLoginViewController.h"

@implementation OKLoginViewNew

-(id)init
{
    self = [super init];
    if(self) {
        // custom init
    }
    return self;
}

-(void)show
{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    window.backgroundColor = [UIColor clearColor];
    
    OKLoginViewController *vc = [[OKLoginViewController alloc] init];
    
    [vc setWindow:window];
    window = nil;
    
    [vc.window setRootViewController:vc];
    [vc.window makeKeyAndVisible];
    [vc showPopup];
}

@end
