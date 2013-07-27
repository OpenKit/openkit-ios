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
-(NSArray*)getCachedScores;
-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID;


@end
