//
//  OKLeaderboard.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HighValue,
    LowValue
} LeaderBoardSortType;

typedef enum {
    OKLeaderboardTimeRangeOneDay,
    OKLeaderboardTimeRangeOneWeek,
    OKLeaderboardTimeRangeAllTime
} OKLeaderboardTimeRange;


@interface OKLeaderboard : NSObject

@property (nonatomic) int OKApp_id;
@property (nonatomic) NSInteger OKLeaderboard_id;
@property (nonatomic) BOOL in_development;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) LeaderBoardSortType sortType;
@property (nonatomic, strong) NSString *icon_url;
@property (nonatomic) int playerCount;

+ (void)getLeaderboardsWithCompletionHandler:(void (^)(NSArray* leaderboards, NSError* error))completionHandler;
- (NSString *)playerCountString;
- (id)initFromJSON:(NSDictionary*)jsonDict;
- (void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange WithCompletionhandler:(void (^)(NSArray* scores, NSError *error))completionHandler;

@end
