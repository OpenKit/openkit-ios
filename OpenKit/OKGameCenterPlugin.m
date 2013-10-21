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
#import "OKError.h"


#define OK_SERVICE_NAME @"gamecenter"

@implementation OKGameCenterPlugin

// Check to see if the device supports GameCenter
// This method is slightly redundant because OpenKit only supports iOS 5+
+ (BOOL)isGCAvailable
{
    return OK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"4.1");
}


+ (OKAuthProvider*)inject
{
    OKAuthProvider *p = [OKAuthProvider providerByName:OK_SERVICE_NAME];
    if(p == nil) {
        p = [[OKGameCenterPlugin alloc] init];
        if([p isAuthenticationAvailable])
            [OKAuthProvider addProvider:p];
    }
    return p;
}


- (id)init
{
    self = [super initWithName:OK_SERVICE_NAME];
    return self;
}


- (BOOL)isAuthenticationAvailable
{
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    return [currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending;
}


- (BOOL)isSessionOpen
{
    return [[GKLocalPlayer localPlayer] isAuthenticated];
}


- (BOOL)start
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(submitScore:) name:OKScoreSubmittedNotification object:self];
    [center addObserver:self selector:@selector(submitAchievement:) name:OKAchievementSubmittedNotification object:nil];
    
    return [self openSessionWithViewController:nil completion:nil];
}


- (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler
{
    [GKLocalPlayer localPlayer].authenticateHandler = ^(UIViewController *gcController, NSError *error)
    {
        [self sessionStateChanged:[[GKLocalPlayer localPlayer] isAuthenticated] error:error];
        if (![GKLocalPlayer localPlayer].isAuthenticated) {
            // local player is not authenticated
            if(controller && gcController) {
                // show the auth dialog
                OKLog(@"Need to show GameCenter dialog");
                [controller presentViewController:gcController animated:YES completion:nil];
            }
        }
        
        if(handler)
            handler([self isSessionOpen], error);
    };
    
    return [self isSessionOpen];
}


- (void)getProfileWithCompletion:(void(^)(OKAuthProfile *profile, NSError *error))handler
{
    NSParameterAssert(handler);
    
    if(![self isSessionOpen]) {
        handler(nil, [OKError sessionClosed]);
        return;
    }
    
    GKLocalPlayer *player = [GKLocalPlayer localPlayer];
    OKAuthProfile *profile = [[OKAuthProfile alloc] initWithProvider:self
                                                              userID:[player playerID]
                                                                name:[player displayName]];
    handler(profile, nil);
}


- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSParameterAssert(handler);
    
    if(![self isSessionOpen]) {
        handler(nil, [OKError sessionClosed]);
        return;
    }
    
    [self getProfileWithCompletion:^(OKAuthProfile *profile, NSError *error)
    {
        GKLocalPlayer *player = [GKLocalPlayer localPlayer];
        [player generateIdentityVerificationSignatureWithCompletionHandler:^(NSURL *publicKeyUrl, NSData *signature, NSData *salt, uint64_t timestamp, NSError *error)
        {
            uint64_t timestampBE = CFSwapInt64HostToBig(timestamp);
            NSMutableData *payload = [[NSMutableData alloc] init];
            [payload appendData:[[profile userID] dataUsingEncoding:NSASCIIStringEncoding]];
            [payload appendData:[[[NSBundle mainBundle] bundleIdentifier] dataUsingEncoding:NSASCIIStringEncoding]];
            [payload appendBytes:&timestampBE length:sizeof(timestampBE)];
            [payload appendData:salt];

            OKAuthRequest *request = nil;
            if(!error)
                request = [[OKAuthRequest alloc] initWithProvider:self
                                                           userID:[profile userID]
                                                     publicKeyUrl:[publicKeyUrl absoluteString]
                                                        signature:signature
                                                             data:payload];
            
            handler(request, error);
        }];
    }];
}


- (void)logoutAndClear
{
    // IMPOSSIBLE
}


- (void)sessionStateChanged:(BOOL)status error:(NSError*)error
{
    switch(status)
    {
        case YES:
            NSLog(@"GameCenterStateOpen");
            break;
        case NO:
            NSLog(@"GameCenterClosed");
            //break;
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OKAuthProviderUpdatedNotification object:self];
}


+ (void)loadPlayersWithIDs:(NSArray*)playerIDs
                completion:(void(^)(NSArray *friends, NSError *error))handler
{
    if(!handler)
        return;
    
    [GKPlayer loadPlayersForIdentifiers:playerIDs withCompletionHandler:handler];
}


+ (void)loadFriendsWithCompletion:(void(^)(NSArray *friendIDs, NSError *error))handler
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


+ (void)loadPlayerPhotoWithID:(NSString*)gameCenterID
                    photoSize:(GKPhotoSize)photoSize
                   completion:(void(^)(UIImage *photo, NSError *error))handler
{
    NSParameterAssert(handler);
    
    [self loadPlayersWithIDs:@[gameCenterID] completion:^(NSArray *players, NSError *error) {
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

+ (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)submitScore:(NSNotification*)not
{
    OKLeaderboard *leaderboard = (OKLeaderboard*)[not object];
    OKScore *score = (OKScore*)[[not userInfo] objectForKey:@"score"];
    NSString *gcLeaderboardID = [[leaderboard services] objectForKey:@"gamecenter"];
    
    if(gcLeaderboardID && [self isSessionOpen])
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
