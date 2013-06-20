//
//  OKSocialLeaderboardViewController.h
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKLeaderboard.h"
#import "OKFBLoginCell.h"

@interface OKSocialLeaderboardViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, OKFBLoginCellDelegate>

@property (nonatomic, strong) OKLeaderboard *leaderboard;
@property (nonatomic, strong) IBOutlet UITableView *_tableView;
@property (nonatomic, strong) IBOutlet UIButton *moreBtn;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSMutableArray *globalScores, *socialScores;

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard;

@end
