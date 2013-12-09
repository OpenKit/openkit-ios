//
//  OKBridgeUIHelper.h
//  OpenKit
//
//  Created by Suneet Shah on 12/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OKManager.h"
#import "OKLeaderboardsViewController.h"

@interface BaseBridgeViewController : UIViewController
{
    BOOL _didDisplay;
    BOOL _didCapturePreviousWindow;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UIWindow *previousWindow;
@end

@interface OKDashBridgeViewController : BaseBridgeViewController <OKManagerDelegate>
@property (nonatomic, retain) OKLeaderboardsViewController *leaderboardsVC;
@property (nonatomic) BOOL shouldShowLandscapeOnly;
@property (nonatomic) int defaultLeaderboardID;
@end

@interface OKGameCenterBridgeViewController : BaseBridgeViewController
@property (nonatomic, retain) UIViewController* gcViewControllerToLaunch;
@end
