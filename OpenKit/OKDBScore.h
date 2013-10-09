//
//  OKDBScore.h
//  OpenKit
//
//  Created by Suneet Shah on 7/26/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKScore.h"
#import "OKDBConnection.h"


@interface OKDBScore : OKDBConnection

@property(nonatomic, strong) OKScore *previousSubmittedScore;

- (NSArray*)getAllScores;
- (NSArray*)getScoresForLeaderboardID:(int)leaderboardID andOnlyGetSubmittedScores:(BOOL)submittedOnly;
- (void)clearSubmittedScores;
- (NSArray*)getUnsubmittedScores;

@end
