//
//  OKScoreCell.m
//  OKClient
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreCell.h"
#import <QuartzCore/QuartzCore.h>


@implementation OKScoreCell

@synthesize label1, label2, label3, label4, score, cellImage;

- (id)init
{
    static NSString *reuseID = kOKScoreCellIdentifier;
    
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseID];
    if (self)
    {
        CGRect CellFrame = CGRectMake(0, 0, 300, 57);
        CGRect NameFrame = CGRectMake(113, 11, 150, 20);
        CGRect ScoreFrame = CGRectMake(113, 28, 150, 20);
        CGRect RankFrame = CGRectMake(0, 0, 44, 60);
        CGRect DateFrame = CGRectMake(240, 0, 50, 60);
        
        [self setFrame:CellFrame];
        
        //cell.backgroundColor = [UIColor redColor];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
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
        label2.font = [UIFont boldSystemFontOfSize:12];
        label2.textColor = [UIColor lightGrayColor];
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
        cellImage = [[OKUserProfileImageView alloc]initWithFrame:CGRectMake(60,10, 39, 39)];
        cellImage.image = [UIImage imageNamed:@"user_icon.png"];
        
        cellImage.layer.masksToBounds = YES;
        cellImage.layer.cornerRadius = 19.5;
        [self.contentView addSubview:cellImage];
        
        // Initialize user icon
        UIImageView *cellBorder = [[UIImageView alloc]initWithFrame:CGRectMake(45,0, 2, 59)];
        cellBorder.image=[UIImage imageNamed:@"cell_border.png"];
        [self.contentView addSubview:cellBorder];
    }
    return self;
}

-(void)setScore:(OKScore *)aScore
{
    score = aScore;
    label1.text = [[score user] userNick];
    label2.text = [NSString stringWithFormat:@"%d",[score scoreValue]];
    label3.text = [NSString stringWithFormat:@"%d",[score scoreRank]];
    [cellImage setUser:[score user]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
