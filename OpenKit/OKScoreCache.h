//
//  OKScoreCache.h
//  OpenKit
//
//  Created by Suneet Shah on 7/26/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKScore.h"

@interface OKScoreCache : NSObject

@property (nonatomic, strong) OKScore *previousSubmittedScore;

+ (OKScoreCache*)sharedCache;

-(NSArray*)getAllCachedScores;
-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID andOnlyGetSubmittedScores:(BOOL)submittedOnly;
-(void)submitCachedScore:(OKScore*)score;
-(void)submitAllCachedScores;
-(void)clearCachedSubmittedScores;

-(void)updateCachedScoreSubmitted:(OKScore*)score;

-(BOOL)isScoreBetterThanLocalCachedScores:(OKScore *)score;
-(void)storeScoreIfBetter:(OKScore*)score;
-(BOOL)isScoreBetterThanLocalCachedScores:(OKScore*)scoreToStore storeScore:(BOOL)shouldStoreScore;


@end
