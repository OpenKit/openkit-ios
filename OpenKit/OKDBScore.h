//
//  OKDBScore.h
//  OpenKit
//
//  Created by Manu Martinez-Almeida.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKScore.h"
#import "OKDBConnection.h"

@interface OKDBScore : OKDBConnection

@property(nonatomic, strong) OKScore *previousSubmittedScore;

- (NSArray*)getAllScores;
- (NSArray*)getScoresForLeaderboardID:(NSInteger)leaderboardID
                        onlySubmitted:(BOOL)submittedOnly;
- (void)clearSubmittedScores;
- (NSArray*)getUnsubmittedScores;

@end
