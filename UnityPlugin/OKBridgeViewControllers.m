//
//  OKBridgeViewControllers.m
//  OpenKit
//
//  Created by Suneet Shah on 9/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
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
    }
}

-(void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:^(void){
        if(completion != nil) {
            completion();
        }
        
        if(_didDisplay) {
            _didDisplay = NO;
            [self.window setRootViewController:nil];
            [self release];
        } else {
            OKBridgeLog(@"dismissViewController called but didDisplayIsFalse");
        }
    }];
}

- (void)dealloc
{
    OKBridgeLog(@"Dealloc BaseBridgeViewController");
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
    OKBridgeLog(@"Showing OKLeaderboardsViewController with default id: %d", _defaultLeaderboardID);
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
/*
 // TODO FIX THIS

@interface OKBridgeGCTest : BaseBridgeViewController
@property (nonatomic, retain) UIViewController *gcViewController;
@end

@implementation OKBridgeGCTest
@synthesize  gcViewController;

- (id)init
{
    if ((self = [super init])) {
    }
    return self;
}

-(void)customLaunch {
    if([self gcViewController] != nil) {
        OKBridgeLog(@"Show gamecenter VC");
        [self presentModalViewController:gcViewController animated:YES];
    }
}

-(void)dealloc
{
    OKBridgeLog(@"OKBridgeGCTest dealloc");
    [super dealloc];
}
 
@end
*/
