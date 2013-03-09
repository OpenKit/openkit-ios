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

#import <UIKit/UIKit.h>

/*
#if TARGET_OS_IPHONE
#import "OKManager.h"
#import "OKGUI.h"
#endif
*/

@interface BridgeViewController : UIViewController
{
    BOOL _didDisplay;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) OKLeaderboardsViewController *leaderboardsVC;
@end

@implementation BridgeViewController

@synthesize window = _window;
@synthesize leaderboardsVC = _leaderboardsVC;

- (id)init
{
    if ((self = [super init])) {
        _didDisplay = NO;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_didDisplay) {
        _didDisplay = YES;
        self.leaderboardsVC = [[[OKLeaderboardsViewController alloc] init] autorelease];
        [self presentModalViewController:self.leaderboardsVC animated:YES];
    } else {
        [self.window setRootViewController:nil];
        [self release];
    }
}

- (void)dealloc
{
    NSLog(@"OpenKit: Deallocing BridgeViewController");
    [_leaderboardsVC release];
    [_window release];
    [super dealloc];
}

@end


void OKBridgeInit(const char *appKey, const char *endpoint)
{
    [OKManager setApplicationID:[NSString stringWithUTF8String:appKey]];
    [OKManager setEndpoint:[NSString stringWithUTF8String:endpoint]];
}

void OKBridgeShowLeaderboards()
{
    UIWindow *win = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    win.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    win.backgroundColor = [UIColor clearColor];

    BridgeViewController *vc = [[BridgeViewController alloc] init];
    vc.window = win;
    [win release];
    // Bridge VC is now responsible for releasing win.  It holds the only reference
    // to it.
    [vc.window setRootViewController:vc];
    [vc.window makeKeyAndVisible];
}

void OKBridgeShowLoginUI()
{
    OKLoginView *loginView = [[OKLoginView alloc] init];
    [loginView show];
    [loginView release];
}

void OKBridgeSubmitScore(int scoreValue, int leaderboardID, const char *gameObjectName)
{
    OKScore *score = [[OKScore alloc] init];
    score.scoreValue = scoreValue;
    score.OKLeaderboardID = leaderboardID;
    OKUser *u = [OKUser currentUser];

    if (!u) {
        // does gameObjectName need to be copied to heap?
        UnitySendMessage(gameObjectName, "scoreSubmissionFailed", "");
    }

    [score submitScoreWithCompletionHandler:^(NSError *error) {
        if(!error) {
            UnitySendMessage(gameObjectName, "scoreSubmissionSucceeded", "");
        } else {
            UnitySendMessage(gameObjectName, "scoreSubmissionFailed", error.description);
        }
    }];
}

int OKBridgeGetCurrentUserOKID()
{
    OKUser *u = [OKUser currentUser];
    return (u ? (int)u.OKUserID : 0);
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



