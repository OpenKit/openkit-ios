//
//  OKSocialLeaderboardViewController.h
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "OKLeaderboard.h"
#import "OKFBLoginCell.h"

@interface OKSocialLeaderboardViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, OKFBLoginCellDelegate,UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@property(nonatomic, strong) OKLeaderboard *leaderboard;
@property(nonatomic) int leaderboardID;
@property(nonatomic, strong) IBOutlet UITableView *_tableView;
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property(nonatomic, strong) MFMailComposeViewController *mail;

@property(nonatomic, strong) IBOutlet UIView *containerViewForLoadMoreButton;
@property(nonatomic, strong) IBOutlet UIButton *loadMoreScoresButton;

@property(nonatomic, strong) NSMutableArray *globalScores, *socialScores;
@property(nonatomic, strong) NSArray *fbSocialScores;
@property(nonatomic, strong) OKScore* playerTopScore, *playerTopScoreSocialSection;

- (id)initWithLeaderboardID:(int)aLeaderboardID;
- (IBAction)loadMoreScoresPressed:(id)sender;

@end
