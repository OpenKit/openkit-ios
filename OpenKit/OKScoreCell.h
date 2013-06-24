//
//  OKScoreCell.h
//  OKClient
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKScore.h"
#import "OKUserProfileImageView.h"
#import "OKGKScoreWrapper.h"

#define kOKScoreCellIdentifier @"OKScoreCell"

@interface OKScoreCell : UITableViewCell

@property (nonatomic, strong) UILabel *label1, *label2, *label3, *label4;
@property (nonatomic, strong) OKScore *score;
@property (nonatomic, strong) OKGKScoreWrapper *gkScoreWrapper;
@property (nonatomic, strong) OKUserProfileImageView *cellImage;


@end
