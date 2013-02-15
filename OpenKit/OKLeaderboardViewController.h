//
//  OKLeaderboardViewController.h
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/4/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKScoreCell.h"
#import "OKLeaderboard.h"

@interface OKLeaderboardViewController : UIViewController
{
    NSMutableArray *listOfItems;
}

@property (nonatomic, strong) OKLeaderboard *leaderboard;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIButton *moreBtn;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSArray *leaderboardScoresToday, *leaderboardScoresAllTime, *leaderboardScoresThisWeek;

@property (nonatomic, strong) IBOutlet UIButton *todayScoresButton, *thisWeekScoresButton, *allTimeScoresButton;

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard;

- (IBAction)showToday:(id)sender;
- (IBAction)showThisWeek:(id)sender;
- (IBAction)showAllTime:(id)sender;
- (IBAction)more:(id)sender;


@end

