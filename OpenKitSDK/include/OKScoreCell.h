//
//  OKScoreCell.h
//  OKClient
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//


#define kOKScoreCellIdentifier @"OKScoreCell"

#import <UIKit/UIKit.h>
#import "OpenKit.h"

@interface OKScoreCell : UITableViewCell

@property (nonatomic, strong) UILabel *label1, *label2, *label3, *label4;
@property (nonatomic, strong) OKScore *score;
@property (nonatomic, strong) OKUserProfileImageView *cellImage;

@end
