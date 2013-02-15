//
//  OKScoreViewCell.h
//  OKClient
//
//  Created by Suneet Shah on 1/16/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreCell.h"

@class OKLeaderboard;

@interface OKScoreViewCell : OKScoreCell

- (void)setScore:(OKScore *)aScore withLeaderboard:(OKLeaderboard *)aLeaderboard;

@end
