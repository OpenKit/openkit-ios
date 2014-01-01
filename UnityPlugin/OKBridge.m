//
//  OKBridge.m
//  OKBridge
//
//  Updated by Lou Zell on 2/14/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
//  Email feedback and suggestions to Lou at lzell11@gmail.com
//

#import "OKBridge.h"
#import "OKUnityHelper.h"
#import "OpenKit.h"
#import "OKGUI.h"
#import "OKHelper.h"
#import "OKFacebookPlugin.h"
#import "OKGameCenterPlugin.h"


extern void UnitySendMessage(const char *, const char *, const char *);


@interface OKBridgeListener : NSObject<OKManagerDelegate, OKGUIDelegate>
@end


@implementation OKBridgeListener

- (void)openkitDidLaunch:(OKManager*)manager
{
    UnitySendMessage("OpenKitPrefab", "NativeDidLaunch", "");
}

- (void)openkitDidChangeStatus:(OKManager*)manager
{
    UnitySendMessage("OpenKitPrefab", "NativeDidChangeStatus", "");
}

- (void)openkitHandledError:(NSError*)error source:(id)source
{
    UnitySendMessage("OpenKitPrefab", "NativeHandledError", "");
}

- (void)openkitWillShowDashboard:(OKGUI*)mgr
{
    UnitySendMessage("OpenKitPrefab", "NativeViewWillAppear", "");
}

- (void)openkitWillHideDashboard:(OKGUI*)mgr
{
    UnitySendMessage("OpenKitPrefab", "NativeViewWillDisappear", "");
}

@end


#pragma mark - Configuration

void OKBridgeConfigureOpenKit(const char *appKey, const char *secretKey)
{
    OKBridgeConfigureOpenKitWithHost(appKey, secretKey, NULL);
}


void OKBridgeConfigureOpenKitWithHost(const char *appKey, const char *secretKey, const char *endpoint)
{
    NSString *ns_appKey = [NSString stringWithUTF8String:appKey];
    NSString *ns_secretKey = [NSString stringWithUTF8String:secretKey];
    NSString *ns_host = endpoint ? [NSString stringWithUTF8String:endpoint] : nil;

    [OKManager configureWithAppKey:ns_appKey secretKey:ns_secretKey host:ns_host];

    OKBridgeListener *listener = [[OKBridgeListener alloc] init];
    [[OKManager sharedManager] setDelegate:listener];
    [[OKGUI sharedManager] setDelegate:listener];
}


void OKBridgeSetLeaderboardListTag(const char *tag)
{
    OKBridgeLog(@"SetLeaderboardListTag");
    [[OKManager sharedManager] setLeaderboardListTag:[NSString stringWithUTF8String:tag]];
}


#pragma mark - Session management

bool OKBridgeIsUserAuthenticated()
{
    return ([OKLocalUser currentUser] != nil);
}

int OKBridgeGetUserID()
{
    OKUser *u = [OKLocalUser currentUser];
    return (u ? [u.userID intValue] : 0);
}

const char* OKBridgeGetUserNick()
{
    OKUser *u = [OKLocalUser currentUser];
    return (u ? OK_HS([u.name UTF8String]) : (char *)0);
}

const char* OKBridgeGetUserFBID()
{
    OKUser *u = [OKLocalUser currentUser];
    const char *fb_id = [[u userIDForService:@"facebook"] UTF8String];
    return (u ? OK_HS(fb_id) : (char *)0);
}

bool OKBridgeIsUserAuthenticatedWithService(const char *serviceName)
{
    NSString *ns_serviceName = [NSString stringWithUTF8String:serviceName];
    return [[OKAuthProvider providerByName:ns_serviceName] isSessionOpen];
}

bool OKBridgeIsUserAuthenticatedWithGameCenter()
{
    return OKBridgeIsUserAuthenticatedWithService("gamecenter");
}

void OKBridgeLogoutUser()
{
    OKBridgeLog(@"Logout of OpenKit");
    [[OKManager sharedManager] logoutCurrentUser];
}

void OKBridgeAuthenticateUserWithService(const char *serviceName)
{
    OKBridgeLog(@"Authenticating local player with %s", serviceName);
    NSString *ns_serviceName = [NSString stringWithUTF8String:serviceName];
    [[OKManager sharedManager] loginWithProviderName:ns_serviceName viewController:nil completion:nil];
}


void OKBridgeAuthenticateUserWithGamecenter()
{
    OKBridgeAuthenticateUserWithService("gamecenter");
}


void OKBridgeAuthenticateUserWithFacebook()
{
    OKBridgeAuthenticateUserWithService("facebook");
}



#pragma mark - Scores

void OKBridgeSubmitScoreBase(OKScore *score, const char *gameObject)
{
    OKBridgeLog(@"Submit score base, game object name is: %s", gameObject);

    __block NSString *ns_gameObject = [NSString stringWithUTF8String:gameObject];
    [score submitWithCompletion:^(NSError *error) {
        if(!error)
            UnitySendMessage([ns_gameObject UTF8String], "scoreSubmissionSucceeded", "");
        else
            UnitySendMessage([ns_gameObject UTF8String], "scoreSubmissionFailed", [[error localizedDescription] UTF8String]);

        [ns_gameObject release];
    }];
}


void OKBridgeSubmitScore(int64_t scoreValue, int leaderboardID, int metadata, const char *displayString, const char *gameObjectName )
{
    OKScore *score = [OKScore scoreWithLeaderboard:leaderboardID];
    [score setValue:scoreValue];
    [score setMetadata:metadata];

    if(displayString != NULL)
        [score setDisplayString:[NSString stringWithUTF8String:displayString]];

    OKBridgeSubmitScoreBase(score, gameObjectName);
}


#pragma mark - UI

void OKBridgeShowLeaderboardsList()
{
    [OKGUI showLeaderboardsListWithClose:nil];
}


void OKBridgeShowLeaderboardID(int leaderboardID)
{
    [OKGUI showLeaderboardID:leaderboardID withClose:nil];
}


void OKBridgeGetFacebookFriends(const char *gameObject)
{
    OKBridgeLog(@"Get fb friends list");

    __block NSString *ns_gameObject = [[NSString alloc] initWithUTF8String:gameObject];
    [OKFacebookPlugin loadFriendsWithCompletion:^(NSArray *friends, NSError *error) {
        
        if(friends && !error){
            NSString *serializedFriends = [OKHelper serializeArray:friends withSorting:YES];
            UnitySendMessage([ns_gameObject UTF8String], "asyncCallSucceeded", [serializedFriends UTF8String]);

        } else{
            if(error) {
                UnitySendMessage([ns_gameObject UTF8String], "asyncCallFailed", [[error localizedDescription] UTF8String]);
            } else {
                UnitySendMessage([ns_gameObject UTF8String], "asyncCallFailed", "Unknown error from native IOS when trying to get Facebook friends");
            }
        }
    }];
}


void OKBridgeShowLoginUI()
{
    [OKGUI showLoginModalWithClose:nil];
}


void OKBridgeShowLoginUIWithBlock(const char *gameObject)
{
    OKBridgeLog(@"Showing OpenKit login window with block");

    __block NSString *ns_gameObject = [[NSString alloc] initWithUTF8String:gameObject];
    [OKGUI showLoginModalWithClose:^{
        OKBridgeLog(@"Login window completion block");
        NSString *paramString = @"OKLoginWindow completed";
        UnitySendMessage([ns_gameObject UTF8String], "asyncCallSucceeded", [paramString UTF8String]);
        [ns_gameObject release];
    }];
}

