//
//  OKSocialLeaderboardViewController.h
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "OKBaseViewController.h"
#import "OKFBLoginCell.h"


@interface OKSocialLeaderboardViewController : OKViewController<UITableViewDataSource, UITableViewDelegate, OKFBLoginCellDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

- (id)initWithLeaderboardID:(int)aLeaderboardID;
- (IBAction)loadMoreScoresPressed:(id)sender;

@end
