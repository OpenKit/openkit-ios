//
//  OKLeaderboard.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUM_SCORES_PER_PAGE 25

typedef enum {
    OKLeaderboardSortTypeHighValue,
    OKLeaderboardSortTypeLowValue
} OKLeaderBoardSortType;

typedef enum {
    OKLeaderboardTimeRangeOneDay,
    OKLeaderboardTimeRangeOneWeek,
    OKLeaderboardTimeRangeAllTime
} OKLeaderboardTimeRange;

@class OKScore;


@interface OKLeaderboard : NSObject

@property(nonatomic) NSInteger leaderboardID;
@property(nonatomic, strong) NSString *name;
@property(nonatomic) OKLeaderBoardSortType sortType;
@property(nonatomic, strong) NSString *iconUrl;
@property(nonatomic) NSUInteger playerCount;
@property(nonatomic, strong) NSDictionary *services;


- (id)initWithDictionary:(NSDictionary*)jsonDict;

- (BOOL)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
                   pageNumber:(NSInteger)pageNum
                   completion:(void (^)(NSArray* scores, NSError *error))handler;

- (BOOL)getSocialScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
                         completion:(void (^)(NSArray* scores, NSError *error))handler;


#pragma mark -

+ (BOOL)getLeaderboardsWithCompletion:(void (^)(NSArray* leaderboards, NSError* error))handler;

+ (BOOL)getLeaderboardWithID:(NSInteger)leaderboardID
                  completion:(void (^)(OKLeaderboard *leaderboard, NSError *error))handler;

+ (void)syncWithCompletion:(void (^)(NSError* error))handler;

@end
