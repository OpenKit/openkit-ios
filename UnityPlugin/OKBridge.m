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
#import "OKManager.h"
#import "OKUnityHelper.h"
#import "OpenKit.h"
#import "OKGameCenterUtilities.h"

#import <UIKit/UIKit.h>

extern void UnitySendMessage(const char *, const char *, const char *);

/*
#if TARGET_OS_IPHONE
#import "OKManager.h"
#import "OKGUI.h"
#endif
*/

@interface BridgeViewController : UIViewController <OKManagerDelegate>
{
    BOOL _didDisplay;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) OKLeaderboardsViewController *leaderboardsVC;
@property (nonatomic) BOOL shouldShowLandscapeOnly;
@end

@implementation BridgeViewController

@synthesize window = _window;
@synthesize leaderboardsVC = _leaderboardsVC;
@synthesize shouldShowLandscapeOnly = _shouldShowLandscapeOnly;

- (id)init
{
    if ((self = [super init])) {
        _didDisplay = NO;
        [[OKManager sharedManager] setDelegate:self];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_didDisplay) {
        _didDisplay = YES;
        self.leaderboardsVC = [[[OKLeaderboardsViewController alloc] init] autorelease];
        // Pass on the shoudlShowLandscape only parameter
        [self.leaderboardsVC setShowLandscapeOnly:_shouldShowLandscapeOnly];
        [self presentModalViewController:self.leaderboardsVC animated:YES];
    } else {
        [self.window setRootViewController:nil];
        [self release];
    }
}

- (void)openkitManagerWillShowDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "OpenKitViewWillAppear", "");
}

- (void)openkitManagerDidShowDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "OpenKitViewDidAppear", "");
}

- (void)openkitManagerWillHideDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "OpenKitViewWillDisappear", "");
}

- (void)openkitManagerDidHideDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "OpenKitViewDidDisappear", "");
}

- (void)dealloc
{
    NSLog(@"OKBridge: Deallocing BridgeViewController");
    [[OKManager sharedManager] setDelegate:nil];
    [_leaderboardsVC release];
    [_window release];
    [super dealloc];
}


@end


void OKBridgeSetAppKey(const char *appKey)
{
    [OKManager setAppKey:[NSString stringWithUTF8String:appKey]];
}

void OKBridgeSetSecretKey(const char *secretKey)
{
    [OKManager setSecretKey:[NSString stringWithUTF8String:secretKey]];
}

void OKBridgeSetEndpoint(const char *endpoint)
{
    [OKManager setEndpoint:[NSString stringWithUTF8String:endpoint]];
}

void OKBridgeShowLeaderboardsBase(BOOL showLandscapeOnly)
{
    UIWindow *win = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    win.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    win.backgroundColor = [UIColor clearColor];

    BridgeViewController *vc = [[BridgeViewController alloc] init];
    // Set shouldShowLandscapeOnly
    [vc setShouldShowLandscapeOnly:showLandscapeOnly];
    
    vc.window = win;
    [win release];
    // Bridge VC is now responsible for releasing win.  It holds the only reference
    // to it.
    [vc.window setRootViewController:vc];
    [vc.window makeKeyAndVisible];
}

void OKBridgeShowLeaderboards()
{
    OKBridgeShowLeaderboardsBase(NO);
}

void OKBridgeShowLeaderboardsLandscapeOnly()
{
    OKBridgeShowLeaderboardsBase(YES);
}

void OKBridgeLogoutCurrentUserFromOpenKit()
{
    NSLog(@"OKBridge: logout of OpenKit");
    [OKUser logoutCurrentUserFromOpenKit];
}

void OKBridgeAuthenticateLocalPlayerWithGameCenter()
{
    NSLog(@"OKBridge: authenticating local player with GC");
    [OKGameCenterUtilities authenticateLocalPlayer];
}

bool OKBridgeIsPlayerAuthenticatedWithGameCenter()
{
    return [OKGameCenterUtilities isPlayerAuthenticatedWithGameCenter];
}

void OKBridgeShowLoginUI()
{
    OKLoginView *loginView = [[OKLoginView alloc] init];
    [loginView show];
    [loginView release];
}

// Base method for submitting a score
void OKBridgeSubmitScoreBase(OKScore *score, const char *gameObjectName)
{
    NSLog(@"OKBridge: Submit score base");
    
    OKUser *u = [OKUser currentUser];
    
    //__block NSString *objName = [[NSString alloc] initWithCString:gameObjectName encoding:NSUTF8StringEncoding];
    __block NSString *objName = [[NSString alloc] initWithUTF8String:gameObjectName];
    
    if (!u) {
        UnitySendMessage([objName UTF8String], "scoreSubmissionFailed", "No current OKUser so score submission failed");
        return;
    }
    
    
    [score submitScoreToOpenKitAndGameCenterWithCompletionHandler:^(NSError *error) {
        if(!error) {
            UnitySendMessage([objName UTF8String], "scoreSubmissionSucceeded", "");
        } else {
            UnitySendMessage([objName UTF8String], "scoreSubmissionFailed", [error.description UTF8String]);
        }
        [objName release];
    }];
}


void OKBridgeSubmitScore(int64_t scoreValue, int leaderboardID, int metadata, const char *displayString, const char *gameObjectName )
{
    OKScore *score = [[OKScore alloc] init];
    score.scoreValue = scoreValue;
    score.OKLeaderboardID = leaderboardID;
    //score.displayString = [[NSString alloc] initWithCString:displayString encoding:NSUTF8StringEncoding];
    //score.displayString = [NSString stringWithFormat:@"%s", displayString];
    
    if(displayString != NULL) {
        score.displayString = [[NSString alloc] initWithUTF8String:displayString];
    }
    
    score.metadata = metadata;

     NSLog(@"OKBridge: Submitting score without GC");
    
    OKBridgeSubmitScoreBase(score, gameObjectName);
}


void OKBridgeSubmitScoreWithGameCenter(int64_t scoreValue, int leaderboardID, int metadata, const char *displayString, const char *gameObjectName, const char *gamecenterLeaderboardID)
{
    OKScore *score = [[OKScore alloc] init];
    score.scoreValue = scoreValue;
    score.OKLeaderboardID = leaderboardID;
    //score.displayString = [[NSString alloc] initWithCString:displayString encoding:NSUTF8StringEncoding];
    if(displayString != NULL) {
        score.displayString = [[NSString alloc] initWithUTF8String:displayString];
    }
    score.metadata = metadata;
    
    if(gamecenterLeaderboardID != NULL) {
        score.gamecenterLeaderboardID = [[NSString alloc] initWithUTF8String:gamecenterLeaderboardID];
    }
    
    NSLog(@"OKBridge: Gamecenter leaderboard ID is: %@", score.gamecenterLeaderboardID);
    NSLog(@"OKBridge: Submitting score with gamecenter");
    OKBridgeSubmitScoreBase(score, gameObjectName);
}


int OKBridgeGetCurrentUserOKID()
{
    OKUser *u = [OKUser currentUser];
    return (u ? [u.OKUserID intValue] : 0);
}

const char* OKBridgeGetCurrentUserNick()
{
    OKUser *u = [OKUser currentUser];
    return (u ? OK_HS([u.userNick UTF8String]) : (char *)0);
}

long long OKBridgeGetCurrentUserFBID()
{
    OKUser *u = [OKUser currentUser];
    return (u ? [u.fbUserID longLongValue] : 0);
}

long long OKBridgeGetCurrentUserTwitterID()
{
    OKUser *u = [OKUser currentUser];
    return (u ? [u.twitterUserID longLongValue] : 0);
}
