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
#import "OKFacebookUtilities.h"
#import "OKMacros.h"

#import <UIKit/UIKit.h>

extern void UnitySendMessage(const char *, const char *, const char *);

/*
#if TARGET_OS_IPHONE
#import "OKManager.h"
#import "OKGUI.h"
#endif
*/




@interface BaseBridgeViewController : UIViewController
{
    BOOL _didDisplay;
}

@property (nonatomic, retain) UIWindow *window;
@end


@implementation BaseBridgeViewController

@synthesize window = _window;

- (id)init
{
    if(self = [super init]) {
        _didDisplay = NO;
    }
    return self;
}

- (void)customLaunch
{
    // Override me.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_didDisplay) {
        _didDisplay = YES;
        [self customLaunch];
    } else {
        [self.window setRootViewController:nil];
        [self release];
    }
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}


@end

@interface OKDashBridgeViewController : BaseBridgeViewController <OKManagerDelegate>
@property (nonatomic, retain) OKLeaderboardsViewController *leaderboardsVC;
@property (nonatomic) BOOL shouldShowLandscapeOnly;
@property (nonatomic) int defaultLeaderboardID;
@end


@implementation OKDashBridgeViewController
@synthesize leaderboardsVC = _leaderboardsVC;
@synthesize shouldShowLandscapeOnly = _shouldShowLandscapeOnly;
@synthesize defaultLeaderboardID = _defaultLeaderboardID;
- (id)init
{
    if ((self = [super init])) {
        [[OKManager sharedManager] setDelegate:self];
    }
    return self;
}

- (void)customLaunch
{
    self.leaderboardsVC = [[[OKLeaderboardsViewController alloc] initWithDefaultLeaderboardID:_defaultLeaderboardID] autorelease];
    [self.leaderboardsVC setShowLandscapeOnly:_shouldShowLandscapeOnly];
    [self presentModalViewController:self.leaderboardsVC animated:YES];
}

- (void)openkitManagerWillShowDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "NativeViewWillAppear", "");
}

- (void)openkitManagerDidShowDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "NativeViewDidAppear", "");
}

- (void)openkitManagerWillHideDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "NativeViewWillDisappear", "");
}

- (void)openkitManagerDidHideDashboard:(OKManager *)manager
{
    UnitySendMessage("OpenKitPrefab", "NativeViewDidDisappear", "");
}

- (void)dealloc
{
    OKBridgeLog(@"Deallocing OKDashboardViewController");
    [[OKManager sharedManager] setDelegate:nil];
    [_leaderboardsVC release];
    [super dealloc];
}

@end


@interface OKGameCenterBridgeViewController : BaseBridgeViewController
@property (nonatomic, retain) UIViewController* gcViewControllerToLaunch;
@end

@implementation OKGameCenterBridgeViewController
#import "OKGameCenterUtilities.h"

@synthesize gcViewControllerToLaunch = _gcViewControllerToLaunch;


- (void)customLaunch
{
    if(_gcViewControllerToLaunch)
        [self presentModalViewController:_gcViewControllerToLaunch animated:YES];
    else
        OKBridgeLog(@"OKGameCenterBridgeViewController VC to launch was null");
}

- (void)dealloc
{
    
    OKBridgeLog(@"Deallocing OKGameCenterBridgeViewController");
    [_gcViewControllerToLaunch release];
    // Release gc stuff if there is any.
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

void OKBridgeShowLeaderboardsBase(BOOL showLandscapeOnly, int defaultLeaderboardID)
{
    UIWindow *win = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    win.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    win.backgroundColor = [UIColor clearColor];

    // Set shouldShowLandscapeOnly & defaultLeaderboardID
    OKDashBridgeViewController *vc = [[OKDashBridgeViewController alloc] init];
    [vc setShouldShowLandscapeOnly:showLandscapeOnly];
    [vc setDefaultLeaderboardID:defaultLeaderboardID];
    
    vc.window = win;
    [win release];
    // Bridge VC is now responsible for releasing win.  It holds the only reference
    // to it.
    [vc.window setRootViewController:vc];
    [vc.window makeKeyAndVisible];
}

void OKBridgeShowLeaderboardID(int leaderboardID, BOOL landscapeOnly)
{
    OKBridgeShowLeaderboardsBase(landscapeOnly, leaderboardID);
}

void OKBridgeShowLeaderboards()
{
    OKBridgeShowLeaderboardsBase(NO,0);
}

void OKBridgeShowLeaderboardsLandscapeOnly()
{
    OKBridgeShowLeaderboardsBase(YES,0);
}

void OKBridgeLogoutCurrentUserFromOpenKit()
{
    OKBridgeLog(@"logout of OpenKit");
    [OKUser logoutCurrentUserFromOpenKit];
}

void OKBridgeAuthenticateLocalPlayerWithGameCenter()
{
    OKBridgeLog(@"authenticating local player with GC");
    [OKGameCenterUtilities authenticateLocalPlayer];
}

void OKBridgeAuthenticateLocalPlayerWithGameCenterAndShowUIIfNecessary()
{
    OKBridgeLog(@"authenticating local player with GC and showing UI if necessary");
    
    //If we need to show UI from GameCenter, then create the OKGameCenterBridgeViewController and display it
    [OKGameCenterUtilities authorizeUserWithGameCenterWithBlockToHandleShowingGameCenterUI:^(UIViewController *viewControllerFromGC) {
        // Need to show gamecenter UI
        UIWindow *win = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        win.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        win.backgroundColor = [UIColor clearColor];
        
        OKGameCenterBridgeViewController *vc = [[OKGameCenterBridgeViewController alloc] init];
        
        [vc setGcViewControllerToLaunch:viewControllerFromGC];
        
        vc.window = win;
        [win release];
        // Bridge VC is now responsible for releasing win.  It holds the only reference
        // to it.
        [vc.window setRootViewController:vc];
        [vc.window makeKeyAndVisible];
    }];
 
}

bool OKBridgeIsPlayerAuthenticatedWithGameCenter()
{
    return [OKGameCenterUtilities isPlayerAuthenticatedWithGameCenter];
}

void OKBridgeGetFacebookFriends(const char *gameObjectName)
{
    OKBridgeLog(@"Get fb friends list");
    __block NSString *objName = [[NSString alloc] initWithUTF8String:gameObjectName];
    
    [OKFacebookUtilities getListOfFriendsForCurrentUserWithCompletionHandler:^(NSArray *friends, NSError *error) {
        
        if(friends && !error){
            NSString *serializedFriends = [OKFacebookUtilities serializeListOfFacebookFriends:friends];
            
            UnitySendMessage([objName UTF8String], "asyncCallSucceeded",[serializedFriends UTF8String]);
        } else{
            if(error) {
                UnitySendMessage([objName UTF8String], "asyncCallFailed", [[error localizedDescription] UTF8String]);
            } else {
                UnitySendMessage([objName UTF8String], "asyncCallFailed", "Unknown error from native IOS when trying to get Facebook friends");
            }
        }
    }];
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
    __block NSString *objName = [[NSString alloc] initWithUTF8String:gameObjectName];
    
    OKBridgeLog(@"Submit score base, game object name is: %s", [objName UTF8String]);
    
    [score submitScoreToOpenKitAndGameCenterWithCompletionHandler:^(NSError *error) {
        
        if(!error) {
            UnitySendMessage([objName UTF8String], "scoreSubmissionSucceeded", "");
        } else {
            UnitySendMessage([objName UTF8String], "scoreSubmissionFailed", [[error localizedDescription] UTF8String]);
        }
        [objName release];
    }];
}


void OKBridgeSubmitScore(int64_t scoreValue, int leaderboardID, int metadata, const char *displayString, const char *gameObjectName )
{
    OKScore *score = [[OKScore alloc] init];
    score.scoreValue = scoreValue;
    score.OKLeaderboardID = leaderboardID;
    
    if(displayString != NULL) {
        score.displayString = [[NSString alloc] initWithUTF8String:displayString];
    }
    
    score.metadata = metadata;

    OKBridgeLog(@"Submitting score without GC");
    
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
    
    OKBridgeLog(@"Gamecenter leaderboard ID is: %@", score.gamecenterLeaderboardID);
    OKBridgeLog(@"Submitting score with gamecenter");
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
