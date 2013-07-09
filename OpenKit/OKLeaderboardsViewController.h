//
//  OKLeaderboardsViewController.h
//  OKClient
//
//  Created by Suneet Shah on 1/10/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OKLeaderboardsViewController : UINavigationController

// Set this property to true to force Leaderboards view to Landscape only (both left and right)
// Set to false to support portrait & landscape
@property (nonatomic) BOOL showLandscapeOnly;

@end
