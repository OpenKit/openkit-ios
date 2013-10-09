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

@property (nonatomic) int OKApp_id;
@property (nonatomic) NSInteger leaderboardID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) OKLeaderBoardSortType sortType;
@property (nonatomic, strong) NSString *iconUrl;
@property (nonatomic) int playerCount;
@property (nonatomic, strong) NSString *gamecenterID;


- (id)initWithDictionary:(NSDictionary*)jsonDict;

+ (void)getLeaderboardsWithCompletion:(void (^)(NSArray* leaderboards, NSError* error))handler;
+ (void)getLeaderboardWithID:(int)leaderboardID withCompletion:(void (^)(OKLeaderboard *leaderboard, NSError *error))handler;

//OpenKit Methods
- (void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange pageNumber:(int)pageNum
       completion:(void (^)(NSArray* scores, NSError *error))handler;
- (void)getPlayerTopScoreForTimeRange:(OKLeaderboardTimeRange)range completion:(void (^)(OKScore *score, NSError *error))handler;
- (void)getFacebookFriendsScoresWithCompletion:(void (^)(NSArray *scores, NSError *error))handler;

//Wrapper methods
- (void)getPlayerTopScoreWithCompletion:(void (^)(OKScore* score, NSError *error))handler;


- (NSSortDescriptor*)getSortDescriptor;
- (NSArray*)sortScoresBasedOnLeaderboardType:(NSArray*)scores;

@end
