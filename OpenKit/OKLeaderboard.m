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


-(void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
       WithCompletionhandler:(void (^)(NSArray* scores, NSError *error))completionHandler
{
    //Create a request and send it to OpenKit
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInt:[self OKLeaderboard_id]] forKey:@"leaderboard_id"];

    OKUser *u = [OKUser currentUser];
    if (u) {
        [params setValue:u.OKUserID forKey:@"user_id"];
    }
    
    if (timeRange != OKLeaderboardTimeRangeAllTime) {
        int days;
        switch (timeRange) {
            case OKLeaderboardTimeRangeOneDay:  days = -1;      break;
            case OKLeaderboardTimeRangeOneWeek: days = -7;      break;
            default:                            days = INT_MIN; break;
        }

        NSDate *since = [OKHelper dateNDaysFromToday:days];
        [params setValue:since forKey:@"since"];
    }
    
    
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/scores" parameters:params
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
                if (u && score.user.OKUserID == u.OKUserID) {
                    NSLog(@"Current user's score is: %d", score.scoreValue);
                }
            }
        }else{
            NSLog(@"Failed to get scores");
        }
        completionHandler(scores, error);
    }];
}


@end
