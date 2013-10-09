//
//  OKProfileViewController.h
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/14/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//


@class OKUserProfileImageView;

@interface OKProfileViewController : UIViewController

@property(nonatomic, strong) IBOutlet UIButton *unlinkBtn;
@property(nonatomic, strong) IBOutlet OKUserProfileImageView *profilePic;
@property(nonatomic, strong) IBOutlet UILabel *nameLabel;

- (IBAction)logoutButtonPressed:(id)sender;

@end
