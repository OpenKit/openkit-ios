//
//  OKScoreCache.m
//  OpenKit
//
//  Created by Suneet Shah on 7/26/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreCache.h"

#define SCORES_CACHE_KEY @"OKLeaderboardScoresCache"

@implementation OKScoreCache

+ (OKScoreCache*)sharedCache
{
    static dispatch_once_t pred;
    static OKScoreCache *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKScoreCache alloc] init];
    });
    return sharedInstance;
}

// Data Storage structure
// Array of cached scores

- (id)init
{
    self = [super init];
    if (self) {
        //init code
    }
    return self;
}

-(void)storeScore:(OKScore*)score
{
    NSMutableArray *mutableScoreCache = [[NSMutableArray alloc] initWithArray:[self getScoreCacheArray]];
    NSData *encodedScore = [NSKeyedArchiver archivedDataWithRootObject:score];
    [mutableScoreCache addObject:encodedScore];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:mutableScoreCache forKey:SCORES_CACHE_KEY];
    [defaults synchronize];
}

-(NSArray*)getCachedScores
{
    NSMutableArray *scoreArray = [[NSMutableArray alloc] init];
    
    NSArray *encodedScoresArray = [self getScoreCacheArray];
    
    for(int x = 0; x < [encodedScoresArray count]; x++)
    {
        NSData *encodedScore = [encodedScoresArray objectAtIndex:x];
        OKScore *score = (OKScore *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedScore];
        [scoreArray addObject:score];
    }
    
    return scoreArray;
}

-(NSArray*)getScoreCacheArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *scoresCache = [defaults objectForKey:SCORES_CACHE_KEY];
    
    // If the cache is not found, return an empty array
    if(scoresCache == nil || ![scoresCache isKindOfClass:[NSArray class]]) {
        return [[NSArray alloc] init];
    } else {
        return scoresCache;
    }
}


- (void)dealloc
{
    // Do not call super here.  Using arc.
}

@end
