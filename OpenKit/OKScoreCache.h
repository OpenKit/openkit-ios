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

+ (OKScoreCache*)sharedCache;

-(void)storeScore:(OKScore*)score;
-(NSArray*)getAllCachedScores;
-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID;
-(void)submitCachedScore:(OKScore*)score;
-(void)submitAllCachedScores;
-(void)clearCache;


//NEW
-(void)storeScore:(OKScore*)score wasScoreSubmitted:(BOOL)submitted;
-(void)removeScore:(OKScore*)score;

@end
