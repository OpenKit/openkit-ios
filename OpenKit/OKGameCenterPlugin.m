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
#import "OKError.h"
#import "OKUtils.h"


#define OK_SERVICE_NAME @"gamecenter"

@implementation OKGameCenterPlugin

+ (OKAuthProvider*)sharedInstance
{
    OKAuthProvider *p = [OKAuthProvider providerByName:OK_SERVICE_NAME];
    if(p == nil) {
        p = [[OKGameCenterPlugin alloc] init];
        [OKAuthProvider addProvider:p];
    }
    return p;
}


- (id)init
{
    self = [super initWithName:OK_SERVICE_NAME];
    return self;
}


- (BOOL)isSessionOpen
{
    return [[GKLocalPlayer localPlayer] isAuthenticated];
}


- (BOOL)isUIVisible
{
    return OK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");
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
        if (![GKLocalPlayer localPlayer].isAuthenticated) {
            // local player is not authenticated
            if(controller && gcController) {
                // show the auth dialog
                [controller presentViewController:gcController animated:YES completion:nil];
            }
        }
        
        if(handler)
            handler([self isSessionOpen], error);
        
        [self sessionStateChanged:[[GKLocalPlayer localPlayer] isAuthenticated] error:error];
    };
    
    return [self isSessionOpen];
}


- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSParameterAssert(handler);
 
    if(!OK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        handler(nil, [OKError noGameCenterIDError]);
        return;
    }
    if(![self isSessionOpen]) {
        handler(nil, [OKError sessionClosed]);
        return;
    }
    
    
    GKLocalPlayer *player = [GKLocalPlayer localPlayer];
    [player generateIdentityVerificationSignatureWithCompletionHandler:^(NSURL *publicKeyUrl, NSData *signature, NSData *salt, uint64_t timestamp, NSError *error)
     {
         uint64_t timestampBE = CFSwapInt64HostToBig(timestamp);
         NSMutableData *payload = [[NSMutableData alloc] init];
         [payload appendData:[[player playerID] dataUsingEncoding:NSASCIIStringEncoding]];
         [payload appendData:[[[NSBundle mainBundle] bundleIdentifier] dataUsingEncoding:NSASCIIStringEncoding]];
         [payload appendBytes:&timestampBE length:sizeof(timestampBE)];
         [payload appendData:salt];
         
         OKAuthRequest *request = nil;
         if(!error) {
             request = [[OKAuthRequest alloc] initWithProvider:self
                                                        userID:[player playerID]
                                                      userName:[player displayName]
                                                  userImageURL:nil
                                                           key:[OKUtils base64Enconding:signature]
                                                          data:[OKUtils base64Enconding:payload]
                                                  publicKeyUrl:[publicKeyUrl absoluteString]];
         }
         
         handler(request, error);
     }];
}


- (void)logoutAndClear
{
    // IMPOSSIBLE
}


- (void)sessionStateChanged:(BOOL)status error:(NSError*)error
{
    if(status == YES) {
        OKLogInfo(@"GameCenterPlugin: Session is open.");
    }else{
        OKLogInfo(@"GameCenterPlugin: Session is closed.");
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OKAuthProviderUpdatedNotification object:self];
}


- (void)loadFriendsWithCompletion:(void(^)(NSArray *friendIDs, NSError *error))handler
{
    if(!handler)
        return;
    
    GKLocalPlayer *player = [GKLocalPlayer localPlayer];
    NSArray *friendsArray = [player friends];
    if(friendsArray)
        handler(friendsArray, nil);
    else {
        [player loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) {
            handler(friends, error);
        }];
    }
}


#pragma mark - Private API

- (void)submitScore:(NSNotification*)not
{
    OKLeaderboard *leaderboard = (OKLeaderboard*)[not object];
    OKScore *score = (OKScore*)[[not userInfo] objectForKey:@"score"];
    NSString *gcLeaderboardID = [[leaderboard services] objectForKey:@"gamecenter"];
    
    if(gcLeaderboardID && [self isSessionOpen])
    {
        GKScore *scoreReporter = [[GKScore alloc] initWithCategory:gcLeaderboardID];
        scoreReporter.value = [score value];
        scoreReporter.context = [score metadata];
        
        [scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
            if(error)
                OKLogErr(@"Error submitting score to GameCenter: %@",error);
            else
                OKLogInfo(@"Gamecenter score submitted successfully");
        }];
    }
}


+ (void)submitAchievement:(NSNotification*)not
{
    
}

@end
