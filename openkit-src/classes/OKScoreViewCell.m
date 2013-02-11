//
//  OKScoreViewCell.m
//  OKClient
//
//  Created by Suneet Shah on 1/16/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreViewCell.h"

@implementation OKScoreViewCell

-(id)init
{
    self = [super init];
    if (self) {
        [self setAccessoryType:UITableViewCellAccessoryNone];
    }
    return self;
}

-(void)setScore:(OKScore *)aScore withLeaderboard:(OKLeaderboard *)aLeaderboard
{
    self.score = aScore;
    
    self.label1.text = [aLeaderboard name];
    self.label2.text = [NSString stringWithFormat:@"%d",[self.score scoreValue]];
    self.label3.text = [NSString stringWithFormat:@"%d",[self.score scoreRank]];
    
    [self.cellImage setImageURL:[aLeaderboard icon_url] withPlaceholderImage:[UIImage imageNamed:@"leaderboard_icon.png"]];
    
    self.label4.text = @"1/12/13";
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
