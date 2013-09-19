//
//  OKGameCenterUtilities.m
//  OpenKit
//
//  Created by Suneet Shah on 6/12/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKGameCenterUtilities.h"
#import "OKUserUtilities.h"
#import "OKMacros.h"
#import "OKManager.h"
#import "OKUser.h"

#define OK_GAMECENTER_AUTH_NOTIFICATION_NAME @"OKGameCenterAuthNotification"

@implementation OKGameCenterUtilities

// Check to see if the device supports GameCenter
// This method is slightly redundant because OpenKit only supports iOS 5+
+(BOOL)isGameCenterAvailable
{
    // Check for presence of GKLocalPlayer API.
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // The device must be running running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}


+(void)fireGameCenterNotification
{
    NSNotification *gcNotification = [NSNotification notificationWithName:OK_GAMECENTER_AUTH_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:gcNotification];
}

+(BOOL)isPlayerAuthenticatedWithGameCenter {
    return [GKLocalPlayer localPlayer].isAuthenticated;
}

// Check to see if we should use iOS5 version of GameCenter authentication or not
+(BOOL)shouldUseLegacyGameCenterAuth
{
    // IF GKLocalPlayer responds to setAuthenticationHandler, then this is iOS 6+ so return NO, otherwise
    // use legacy version (return YES)
    
    if([[GKLocalPlayer localPlayer] respondsToSelector:@selector(setAuthenticateHandler:)])
        return NO;
    else
        return YES;
}


+(void)authenticateLocalPlayerWithCompletionHandler:(OKGameCenterLoginCompletionHandler)completionHandler showUI:(BOOL)showUI presentingViewController:(UIViewController*)presenter
{
    // If on iOS5, use the legacy game center auth
    if([self shouldUseLegacyGameCenterAuth]) {
        [self authenticateLocalPlayerLegacyWithCompletionHandler:completionHandler];
        return;
    }
    
    [GKLocalPlayer localPlayer].authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        
        if(viewController != nil) {
            // show the auth dialog
            OKLog(@"Need to show GameCenter dialog");
            if(presenter && showUI) {
                [presenter presentModalViewController:viewController animated:YES];
            } else if (!presenter && showUI) {
                OKLog(@"Did not pass in presenting view controller");
            }
        } else if ([GKLocalPlayer localPlayer].isAuthenticated) {
            // local player is authenticated
            [self fireGameCenterNotification];
            OKLog(@"Authenticated with GameCenter");
        } else {
            [self fireGameCenterNotification];
            OKLog(@"Did not auth with GameCenter, error: %@", error);
        }
    };
}



// Authenticate with GameCenter on iOS5
+(void)authenticateLocalPlayerLegacyWithCompletionHandler:(OKGameCenterLoginCompletionHandler)completionHandler {
    
    // This gamecenter method is deprecated in iOS6 but is required for iOS 5 support
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
        
        [self fireGameCenterNotification];
        
        if (localPlayer.isAuthenticated)
        {
            // local player is authenticated
            OKLog(@"Authenticated with GameCenter iOS5 style");
        }
        else
        {
            // local player is not authenticated
            OKLog(@"Did not auth with GameCenter (iOS5 style), error: %@", error);
        }
        
        if(completionHandler) {
            completionHandler(error);
        }
    }];
}



+(void)loadPlayerPhotoForGameCenterID:(NSString*)gameCenterID withPhotoSize:(GKPhotoSize)photoSize withCompletionHandler:(void(^)(UIImage *photo, NSError *error))completionhandler
{
    [GKPlayer loadPlayersForIdentifiers:[NSArray arrayWithObject:gameCenterID] withCompletionHandler:^(NSArray *players, NSError *error) {
        if (error != nil)
        {
            // Couldn't load the player info, so can't load profile photo
            completionhandler(nil,error);
        }
        else if (players != nil)
        {
            GKPlayer *player = [players objectAtIndex:0];
            [player loadPhotoForSize:photoSize withCompletionHandler:^(UIImage *photo, NSError *error) {
                completionhandler(photo, error);
            }];
        }
        else {
            completionhandler(nil,error);
        }
    }];
}



@end
