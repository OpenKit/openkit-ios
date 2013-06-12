//
//  OKGameCenterUtilities.m
//  OpenKit
//
//  Created by Suneet Shah on 6/12/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKGameCenterUtilities.h"
#import <GameKit/GameKit.h>
#import "OKUserUtilities.h"
#import "OKMacros.h"

@implementation OKGameCenterUtilities

+(void)authorizeUserWithGameCenterAndallowUI:(BOOL)allowUI
{
    [GKLocalPlayer localPlayer].authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        
        if(viewController != nil) {
            // show the auth dialog
            OKLog(@"Need to show GameCenter dialog");
        } else if ([GKLocalPlayer localPlayer].isAuthenticated) {
            // local player is authenticated
            OKLog(@"Authenticated with GameCenter");
            
            //[OKUserUtilities a]
            
        } else {
            // local player is not authenticated
            OKLog(@"Did not auth with GameCenter, error: %@", error);
        }
    };
}

@end
