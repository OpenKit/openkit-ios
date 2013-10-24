//
//  OKScoreCell.m
//  OKClient
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreCell.h"
#import <QuartzCore/QuartzCore.h>
#import "OKMacros.h"
#import "OKColors.h"


@interface OKScoreCell ()

@property(nonatomic, strong) UILabel *label1, *label2, *label3, *label4;
@property(nonatomic, strong) AFImageView *cellImage;
@property(nonatomic, strong) UIImageView *socialNetworkIconImageView;
@property(nonatomic) BOOL showSocialNetworkIcon;

@end


@implementation OKScoreCell

- (id)init
{
    static NSString *reuseID = kOKScoreCellIdentifier;
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID];
    if (self)
    {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        CGRect userProfileImageFrame = CGRectMake(47,10, 39, 39);
        float socialNetworkIconSize = 16.0;
        
        CGRect socialNetworkIconFrame = CGRectMake(userProfileImageFrame.origin.x+userProfileImageFrame.size.width - socialNetworkIconSize/2 - 3, userProfileImageFrame.origin.y + userProfileImageFrame.size.height - socialNetworkIconSize/2 - 3, socialNetworkIconSize, socialNetworkIconSize);
        
        
        // Initialize user icon
        _cellImage = [[AFImageView alloc]initWithFrame:userProfileImageFrame];
        [_cellImage setImage:[UIImage imageNamed:@"user_icon.png"]];
        [_cellImage.layer setMasksToBounds:YES];
        [_cellImage.layer setCornerRadius:3];
        [self.contentView addSubview:_cellImage];
        
        //Initialize social network icon
        _socialNetworkIconImageView = [[UIImageView alloc] initWithFrame:socialNetworkIconFrame];
        [_socialNetworkIconImageView setHidden:YES];
        [self.contentView addSubview:_socialNetworkIconImageView];
        
        //Score cell is not selectable
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}


- (void)setScore:(OKScore *)aScore
{    
    // Update the text fields
    _label1.text = [aScore userDisplayString];
    _label2.text = [aScore scoreDisplayString];
    _label3.text = [aScore rankDisplayString];
    
    // Show the player image
    OKUser *user = [aScore user];
    [_cellImage setImageWithURL:[NSURL URLWithString:[user userImageUrl]] placeholderImage:[UIImage imageNamed:@"user_icon.png"]];
    
    
    NSArray *connections = [user resolveConnections];
    if([connections count] > 0){
        [_socialNetworkIconImageView setHidden:NO];
    }else
    {
        [_socialNetworkIconImageView setHidden:YES];
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
