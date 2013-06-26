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


@implementation OKScoreCell

@synthesize label1, label2, label3, label4, score, cellImage, OKScoreProtocolScore;

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
        [self setFrame:CellFrame];
        
        [self setBackgroundColor:[UIColor whiteColor]];
        
        //Removing accessory view for now because we're not showing the
        // score view
        //self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        //Initialize Label with tag 1.
        label1 = [[UILabel alloc] initWithFrame:NameFrame];
        label1.tag = 1;
        label1.lineBreakMode = UILineBreakModeTailTruncation;
        label1.font = [UIFont boldSystemFontOfSize:15];
        label1.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:label1];
        
        //Initialize Label with tag 2.
        label2 = [[UILabel alloc] initWithFrame:ScoreFrame];
        label2.tag = 2;
        label2.font = [UIFont systemFontOfSize:12];
        label2.textColor = UIColorFromRGB(0x828282);
        label2.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:label2];
        
        //Initialize Label with tag 3.
        label3 = [[UILabel alloc] initWithFrame:RankFrame];
        label3.tag = 3;
        label3.font = [UIFont boldSystemFontOfSize:15];
        label3.backgroundColor = [UIColor clearColor];
        label3.textAlignment = NSTextAlignmentCenter;
        label3.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label3];
        
        //Initialize Label with tag 4.
        label4 = [[UILabel alloc] initWithFrame:DateFrame];
        label4.tag = 4;
        label4.font = [UIFont boldSystemFontOfSize:12];
        label4.textColor = [UIColor lightGrayColor];
        label4.backgroundColor = [UIColor clearColor];
        label4.textAlignment = NSTextAlignmentCenter;
        label4.adjustsFontSizeToFitWidth = YES;
        label4.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:label4];

        
        // Initialize user icon
        cellImage = [[OKUserProfileImageView alloc]initWithFrame:userProfileImageFrame];
        cellImage.image = [UIImage imageNamed:@"user_icon.png"];
        
        cellImage.layer.masksToBounds = YES;
        cellImage.layer.cornerRadius = 3;
        [self.contentView addSubview:cellImage];
        
        // Initialize user icon
        //UIImageView *cellBorder = [[UIImageView alloc]initWithFrame:CGRectMake(45,0, 2, 59)];
        //cellBorder.image=[UIImage imageNamed:@"cell_border.png"];
        //[self.contentView addSubview:cellBorder];
    }
    return self;
}


-(void)setOKScoreProtocolScore:(id<OKScoreProtocol>)aScore
{
    OKScoreProtocolScore = aScore;
    
    // Update the text fields
    label1.text = [OKScoreProtocolScore userDisplayString];
    label2.text = [OKScoreProtocolScore scoreDisplayString];
    label3.text = [OKScoreProtocolScore rankDisplayString];
    
    // Show the player image
    [cellImage setOKScoreProtocolScore:OKScoreProtocolScore];
}

// Older implementation --> use setIScore now
-(void)setScore:(OKScore *)aScore
{
    score = aScore;
    label1.text = [[score user] userNick];
    
    // Show the display string if not nil, else show the score value
    if([score displayString] != nil) {
        label2.text = [score displayString];
    } else {
        label2.text = [NSString stringWithFormat:@"%lld",[score scoreValue]];
    }
    
    //Set the rank
    label3.text = [NSString stringWithFormat:@"%d",[score scoreRank]];
    
    [cellImage setUser:[score user]];
}

/*
-(void)setGkScoreWrapper:(OKGKScoreWrapper*)aScore {
    gkScoreWrapper = aScore;
    
    label1.text = [[gkScoreWrapper player] displayName];
    label2.text = [[gkScoreWrapper score] formattedValue];
    label3.text = [NSString stringWithFormat:@"%d",[[gkScoreWrapper score] rank]];
    
    [cellImage setGKPlayer:[gkScoreWrapper player]];
}
 */

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
