//
//  OKScoreViewController.h
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/14/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//


#import "OKScore.h"

@class OKLeaderboard;
@class OKScore;
@interface OKScoreViewController : UIViewController

@property (nonatomic, weak) OKScore *currentScore;
@property (nonatomic, weak) OKLeaderboard *currentLeaderboard;

@property (weak, nonatomic) IBOutlet UIButton *facebookBtn;
@property (weak, nonatomic) IBOutlet UIButton *twitterBtn;
@property (weak, nonatomic) IBOutlet UITableView *detail;

- (id)initWithScore:(OKScore*)aScore withLeaderboard:(OKLeaderboard*)aLeaderboard;

@end
