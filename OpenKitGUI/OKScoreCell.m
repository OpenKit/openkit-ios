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


@implementation OKScoreCell

- (id)init
{
    static NSString *reuseID = kOKScoreCellIdentifier;
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID];
    if (self)
    {
        CGRect CellFrame = CGRectMake(0, 0, 300, 57);
        CGRect NameFrame = CGRectMake(100, 11, 150, 20);
        CGRect ScoreFrame = CGRectMake(100, 28, 150, 20);
        CGRect RankFrame = CGRectMake(0, 0, 44, 60);
        CGRect DateFrame = CGRectMake(227, 0, 50, 60);
        CGRect userProfileImageFrame = CGRectMake(47,10, 39, 39);
        
        float socialNetworkIconSize = 16.0;
        
        CGRect socialNetworkIconFrame = CGRectMake(userProfileImageFrame.origin.x+userProfileImageFrame.size.width - socialNetworkIconSize/2 - 3, userProfileImageFrame.origin.y + userProfileImageFrame.size.height - socialNetworkIconSize/2 - 3, socialNetworkIconSize, socialNetworkIconSize);
        
        
        [self setFrame:CellFrame];
        
        [self setBackgroundColor:[UIColor whiteColor]];
        
        //Removing accessory view for now because we're not showing the
        // score view
        //self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        //Initialize Label with tag 1.
        _label1 = [[UILabel alloc] initWithFrame:NameFrame];
        _label1.tag = 1;
        _label1.lineBreakMode = UILineBreakModeTailTruncation;
        _label1.font = [UIFont boldSystemFontOfSize:15];
        _label1.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_label1];
        
        //Initialize Label with tag 2.
        _label2 = [[UILabel alloc] initWithFrame:ScoreFrame];
        _label2.tag = 2;
        _label2.font = [UIFont systemFontOfSize:12];
        _label2.textColor = UIColorFromRGB(0x828282);
        _label2.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_label2];
        
        //Initialize Label with tag 3.
        _label3 = [[UILabel alloc] initWithFrame:RankFrame];
        _label3.tag = 3;
        _label3.font = [UIFont boldSystemFontOfSize:15];
        _label3.backgroundColor = [UIColor clearColor];
        _label3.textAlignment = NSTextAlignmentCenter;
        _label3.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:_label3];
        
        //Initialize Label with tag 4.
        _label4 = [[UILabel alloc] initWithFrame:DateFrame];
        _label4.tag = 4;
        _label4.font = [UIFont boldSystemFontOfSize:12];
        _label4.textColor = [UIColor lightGrayColor];
        _label4.backgroundColor = [UIColor clearColor];
        _label4.textAlignment = NSTextAlignmentCenter;
        _label4.adjustsFontSizeToFitWidth = YES;
        _label4.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:_label4];

        
        // Initialize user icon
        _cellImage = [[OKUserProfileImageView alloc]initWithFrame:userProfileImageFrame];
        _cellImage.image = [UIImage imageNamed:@"user_icon.png"];
        _cellImage.layer.masksToBounds = YES;
        _cellImage.layer.cornerRadius = 3;
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

- (void)setShowSocialNetworkIcon:(BOOL)aShowSocialNetworkIcon
{
    _showSocialNetworkIcon = aShowSocialNetworkIcon;
    
    if(_showSocialNetworkIcon) {
        [_socialNetworkIconImageView setHidden:NO];
    } else {
        [_socialNetworkIconImageView setHidden:YES];
    }
    
}

- (void)setSocialNetworkIconForNetwork:(OKScoreSocialNetwork)socialNetwork
{
    switch (socialNetwork) {
        case OKScoreSocialNetworkFacebook:
            [_socialNetworkIconImageView setImage:[UIImage imageNamed:@"facebook_icon.png"]];
            break;
        case OKScoreSocialNetworkGameCenter:
            [_socialNetworkIconImageView setImage:[UIImage imageNamed:@"gamecenter_icon.png"]];
            break;
        default:
            [_socialNetworkIconImageView setImage:nil];
            break;
    }
}


- (void)setOKScoreProtocolScore:(OKScore*)aScore
{
    _OKScoreProtocolScore = aScore;
    
    // Update the text fields
    _label1.text = [_OKScoreProtocolScore userDisplayString];
    _label2.text = [_OKScoreProtocolScore scoreDisplayString];
    _label3.text = [_OKScoreProtocolScore rankDisplayString];
    
    // Show the player image
    [_cellImage setOKScoreProtocolScore:_OKScoreProtocolScore];
    
    // Set the social network icon REVIEW
    // [self setSocialNetworkIconForNetwork:[aScore socialNetwork]];
}


// Older implementation --> use setIScore now
- (void)setScore:(OKScore *)aScore
{
    _score = aScore;
    _label1.text = [[_score user] userNick];
    
    // Show the display string if not nil, else show the score value
    if([_score displayString] != nil) {
        _label2.text = [_score displayString];
    } else {
        _label2.text = [NSString stringWithFormat:@"%lld",[_score scoreValue]];
    }
    
    //Set the rank
    _label3.text = [NSString stringWithFormat:@"%d",[_score scoreRank]];
    
    [_cellImage setUser:[_score user]];
    
    // Set the social network icon
    [self setSocialNetworkIconForNetwork:[aScore socialNetwork]];
    
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
