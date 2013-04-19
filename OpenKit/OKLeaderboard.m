//
//  OKLeaderboard.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLeaderboard.h"
#import "OKManager.h"
#import "OKUser.h"
#import "OKScore.h"
#import "OKHelper.h"
#import "OKNetworker.h"

#define NUM_SCORES_PER_PAGE 25

@implementation OKLeaderboard

@synthesize OKLeaderboard_id, OKApp_id, name, in_development, sortType, icon_url, playerCount;

- (id)initFromJSON:(NSDictionary*)jsonDict
{
    if ((self = [super init])) {
        NSString *sortTypeString    = (NSString*)[jsonDict objectForKey:@"sort_type"];

        self.name                   = [jsonDict objectForKey:@"name"];
        self.OKLeaderboard_id       = [[jsonDict objectForKey:@"id"] integerValue];
        self.OKApp_id               = [[jsonDict objectForKey:@"app_id"] integerValue];
        self.in_development         = [[jsonDict objectForKey:@"in_development"] boolValue];
        self.sortType               = ([sortTypeString isEqualToString:@"HighValue"]) ? HighValue : LowValue;
        self.icon_url               = [jsonDict objectForKey:@"icon_url"];
        self.playerCount            = [[jsonDict objectForKey:@"player_count"] integerValue];

        //_timeRange = OKLeaderboardTimeRangeOneDay;
    }

    return self;
}

- (NSString *)playerCountString
{
    return [NSString stringWithFormat:@"%d Players", playerCount];
}

+ (void)getLeaderboardsWithCompletionHandler:(void (^)(NSArray* leaderboards, NSError* error))completionHandler
{
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/leaderboards" parameters:nil
                     handler:^(id responseObject, NSError *error)
     {
         NSMutableArray *leaderboards = nil;
         if(!error) {
             NSLog(@"Successfully got list of leaderboards");
             NSLog(@"Leaderboard response is: %@", responseObject);
             NSArray *leaderBoardsJSON = (NSArray*)responseObject;
             leaderboards = [NSMutableArray arrayWithCapacity:[leaderBoardsJSON count]];
             
             for(id obj in leaderBoardsJSON) {
                 OKLeaderboard *leaderBoard = [[OKLeaderboard alloc] initFromJSON:obj];
                 [leaderboards addObject:leaderBoard];
             }
         }else{
             NSLog(@"Failed to get list of leaderboards: %@", error);
         }
         completionHandler(leaderboards, error);
     }];
}

-(void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange WithCompletionhandler:(void (^)(NSArray *, NSError *))completionHandler
{
    [self getScoresForTimeRange:timeRange forPageNumber:1 WithCompletionhandler:completionHandler];
}

-(NSString*)getParamForLeaderboardTimeRange:(OKLeaderboardTimeRange)range
{
    switch (range) {
        case OKLeaderboardTimeRangeOneDay:
            return @"today";
        case OKLeaderboardTimeRangeOneWeek:
            return @"this_week";
        default:
            return @"all_time";
    }
}

-(void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange forPageNumber:(int)pageNum 
       WithCompletionhandler:(void (^)(NSArray* scores, NSError *error))completionHandler
{
    //Create a request and send it to OpenKit
    //Create the request parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInt:[self OKLeaderboard_id]] forKey:@"leaderboard_id"];
    [params setValue:[NSNumber numberWithInt:pageNum] forKey:@"page_num"];
    [params setValue:[NSNumber numberWithInt:NUM_SCORES_PER_PAGE] forKey:@"num_per_page"];
    [params setValue:[self getParamForLeaderboardTimeRange:timeRange] forKey:@"leaderboard_range"];
    
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/best_scores" parameters:params
                     handler:^(id responseObject, NSError *error)
    {
        NSMutableArray *scores = nil;
        if(!error) {
            NSLog(@"Successfully got scores: %@", responseObject);

            NSArray *scoresJSON = (NSArray*)responseObject;
            scores = [NSMutableArray arrayWithCapacity:[scoresJSON count]];
            
            for(id obj in scoresJSON) {
                OKScore *score = [[OKScore alloc] initFromJSON:obj];
                [scores addObject:score];
            }
        } else {
            NSLog(@"Failed to get scores, with error: %@", error);
        }
        completionHandler(scores, error);
    }];
}

-(void)getUsersTopScoreForLeaderboardForTimeRange:(OKLeaderboardTimeRange)range withCompletionHandler:(void (^)(OKScore *score, NSError *error))completionHandler
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInt:[self OKLeaderboard_id]] forKey:@"leaderboard_id"];
    [params setValue:[self getParamForLeaderboardTimeRange:range] forKey:@"leaderboard_range"];
    [params setValue:[[OKUser currentUser] OKUserID] forKey:@"user_id"];
    
    [OKNetworker getFromPath:@"best_scores/user" parameters:params handler:^(id responseObject, NSError *error) {
        if(!error) {
            OKScore *topScore = [[OKScore alloc] initFromJSON:(NSDictionary*)responseObject];
            completionHandler(topScore, nil);
        }
        else {
            completionHandler(nil, error);
        }
    }];
}


@end
