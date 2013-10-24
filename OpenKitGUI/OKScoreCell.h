//
//  OKScoreCell.h
//  OKClient
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFImageView.h"
#import "OKScore.h"
#import "OKUserProfileImageView.h"

#define kOKScoreCellIdentifier @"OKScoreCell"


@interface OKScoreCell : UITableViewCell

- (void)setScore:(OKScore*)score;

@end
