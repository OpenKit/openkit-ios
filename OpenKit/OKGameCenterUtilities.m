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
            [self loginToOpenKitWithGameCenterUser:[GKLocalPlayer localPlayer]];
        } else {
            // local player is not authenticated
            OKLog(@"Did not auth with GameCenter, error: %@", error);
        }
    };
}

/** Manages the logic for logging into OpenKit with GameCenter **/
+(void)loginToOpenKitWithGameCenterUser:(GKPlayer*)player
{
    OKLog(@"Logging into OpenKit with GameCenter");
     // If there is already a cached OKUser, then update the user for GameCenter
    if([OKUser currentUser] != nil) {
        [self updateOKUserForGamecenterUser:player withOKUser:[OKUser currentUser]];
    }
    else {
        [self getOKUserWithGamecenterUser:[GKLocalPlayer localPlayer]];
    }
}

/** Given an OKUser and a GKPlayer, decides whether the cached OKUser should be updated to reflect the GameCenter ID, or should be logged out and a new OKUser should be created **/
+(void)updateOKUserForGamecenterUser:(GKPlayer*)player withOKUser:(OKUser*)user
{
    if([user gameCenterID] == nil) {
        //Current user doesn't have a game center ID, but it should have some other type of ID
        // TODO, add GameCenter ID to current user, e.g. UPDATE the user
        OKLog(@"TODO update existing user with GameCenter ID");
    }
    else if (![[user gameCenterID] isEqualToString:[player playerID]]) {
        OKLog(@"New GameCenter user found from previous cached gamecenter user");
        // If the cached/current OKUser's GC ID != localPlayer GC ID, then logout and re-login
        [[OKManager sharedManager] logoutCurrentUser];
        [self getOKUserWithGamecenterUser:player];
    }
}

/** Given a GKPlayer, sends a POST to OKUSer with that gamecenter ID--> "create or get"
    If the login is successful, OKUser is cached as the currentUser
 **/
+(void)getOKUserWithGamecenterUser:(GKPlayer*)player
{
    [OKUserUtilities createOKUserWithUserIDType:GameCenterIDType withUserID:[player playerID] withUserNick:[player displayName] withCompletionHandler:^(OKUser *user, NSError *error) {
        
        if(!error) {
            //Save the current user
            [user setGameCenterID:[player playerID]];
            [[OKManager sharedManager] saveCurrentUser:user];
            OKLog(@"Logged into OpenKit with GameCenter ID: %@, display name: %@",[player playerID], [user userNick]);
        } else {
            OKLog(@"Failed to login to OpenKit with gamecenter ID");
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

+(BOOL)gameCenterIsAvailable {
    return [GKLocalPlayer localPlayer].isAuthenticated;
}

@end
