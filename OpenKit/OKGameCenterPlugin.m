//
//  OKScore.m
//  OKClient
//
//  Created by Suneet Shah and Manu Mtz-Almeida.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "OKGameCenterPlugin.h"
#import "OKNotifications.h"
#import "OKScore.h"
#import "OKLeaderboard.h"
#import "OKMacros.h"
#import "OKChallenge.h"


@implementation OKGameCenterPlugin

// Check to see if the device supports GameCenter
// This method is slightly redundant because OpenKit only supports iOS 5+
+ (BOOL)isGCAvailable
{
    // Check for presence of GKLocalPlayer API.
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // The device must be running running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}


+ (BOOL)isPlayerAuthenticated {
    return [GKLocalPlayer localPlayer].isAuthenticated;
}


+ (void)logout
{
    [self removeNotifications];
}


+ (void)authorizeUserWithViewController:(UIViewController*)controller completion:(void(^)(NSError* error))handler
{
    [self registerNotifications];
    
    // There are two ways to authorize users depending the OS version
    if([self shouldUseLegacyGameCenterAuth])
        [OKGameCenterPlugin authorizeUserV1WithCompletion:handler];
    else
        [OKGameCenterPlugin authorizeUserV2WithViewController:controller completion:handler];
}


+ (void)authorizeUserV1WithCompletion:(void(^)(NSError* error))handler
{
    // This gamecenter method is deprecated in iOS6 but is required for iOS 5 support
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:OKGameCenterPluginAuthStateNotification object:nil];

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
        
        if(handler)
            handler(error);
    }];
}


+ (void)authorizeUserV2WithViewController:(UIViewController*)controller completion:(void(^)(NSError* error))handler
{
    // This gamecenter method is deprecated in iOS 5 support
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *gcController, NSError *error)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:OKGameCenterPluginAuthStateNotification object:nil];

        if ([GKLocalPlayer localPlayer].isAuthenticated) {
            // local player is authenticated
            OKLog(@"Authenticated with GameCenter");
            
        } else {
            
            // local player is not authenticated
            OKLog(@"Did not auth with GameCenter, error: %@", error);
            if(controller && gcController) {
                // show the auth dialog
                OKLog(@"Need to show GameCenter dialog");
                [controller presentModalViewController:gcController animated:YES];
            }
        }
        
        if(handler)
            handler(error);
    };
}


// Check to see if we should use iOS5 version of GameCenter authentication or not
+(BOOL)shouldUseLegacyGameCenterAuth
{
    //TODO remove this workaround-- using legacy auth right now always because of Unity
    //return YES;
    
    // IF GKLocalPlayer responds to setAuthenticationHandler, then this is iOS 6+ so return NO, otherwise
    // use legacy version (return YES)
    
    if([[GKLocalPlayer localPlayer] respondsToSelector:@selector(setAuthenticateHandler:)])
        return NO;
    else
        return YES;
}


+ (void)loadFriendIDsWithCompletion:(void(^)(NSArray *friendIDs, NSError *error))handler
{
    if(!handler)
        return;
    
    GKLocalPlayer *player = [GKLocalPlayer localPlayer];
    
    NSArray *friends = [player friends];
    if(friends)
        handler(friends, nil);
    else {
        [player loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) {
            handler(friends, error);
        }];
    }
}


+ (void)loadPlayersWithIDs:(NSArray*)playerIDs completion:(void(^)(NSArray *friends, NSError *error))handler
{
    if(!handler)
        return;
    
    [GKPlayer loadPlayersForIdentifiers:playerIDs withCompletionHandler:handler];
}


+ (void)loadFriendsWithCompletion:(void(^)(NSArray *friendIDs, NSError *error))handler
{
    [self loadFriendIDsWithCompletion:^(NSArray *friendIDs, NSError *error) {
        [self loadPlayersWithIDs:friendIDs completion:handler];
    }];
}


+ (void)loadPlayerPhotoWithID:(NSString*)gameCenterID
                    photoSize:(GKPhotoSize)photoSize
                   completion:(void(^)(UIImage *photo, NSError *error))handler
{
    [self loadPlayersWithIDs:[NSArray arrayWithObject:gameCenterID] completion:^(NSArray *players, NSError *error) {
        if (!error && players) {
            GKPlayer *player = [players objectAtIndex:0];
            [player loadPhotoForSize:photoSize withCompletionHandler:^(UIImage *photo, NSError *error) {
                handler(photo, error);
            }];
            
        }else{
            // Couldn't load the player info, so can't load profile photo
            handler(nil,error);
        }
    }];
}


#pragma mark - Private API

+ (void)registerNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(submitScore:) name:OKNotificationSubmittedScore object:self];
    [center addObserver:self selector:@selector(submitAchievement:) name:OKNotificationSubmittedAchievement object:nil];
}


+ (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (void)submitScore:(NSNotification*)not
{
    OKLeaderboard *leaderboard = (OKLeaderboard*)[not object];
    OKScore *score = (OKScore*)[[not userInfo] objectForKey:@"score"];
    NSString *gcLeaderboardID = [leaderboard gamecenterID];
    
    if(gcLeaderboardID && [OKGameCenterPlugin isPlayerAuthenticated])
    {
        GKScore *scoreReporter = [[GKScore alloc] initWithCategory:gcLeaderboardID];
        scoreReporter.value = [score scoreValue];
        scoreReporter.context = [score metadata];
        
        [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
            if(error)
                OKLog(@"Error submitting score to GameCenter: %@",error);
            else
                OKLog(@"Gamecenter score submitted successfully");
        }];
        
    } else {
        OKLog(@"Not submitting score to GameCenter, GC not available");
    }
}


+ (void)submitAchievement:(NSNotification*)not
{
    
}


@end

