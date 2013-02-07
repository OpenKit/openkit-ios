//
//  OKLeaderboard.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLeaderboard.h"
#import "OpenKit.h"
#import "OKHelper.h"

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
    AFHTTPClient *OK_HTTPClient = [[OpenKit sharedInstance] httpClient];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[OpenKit getApplicationID] forKey:@"app_key"];
    
    NSMutableURLRequest *request = [OK_HTTPClient requestWithMethod:@"GET" path:@"/leaderboards" parameters:params];
    AFHTTPRequestOperation *operation = [OK_HTTPClient HTTPRequestOperationWithRequest:request
                                                                               success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSArray *leaderBoardsJSON = (NSArray*)responseObject;
         int numLeaderboards = [leaderBoardsJSON count];
         NSLog(@"Successfully got list of leaderboards");
         NSLog(@"Leaderboard response is: %@", responseObject);
         
         if (numLeaderboards > 0) {
             NSMutableArray *leaderBoardsList = [[NSMutableArray alloc] init];
             for (int x = 0; x < numLeaderboards; x++) {
                 OKLeaderboard *leaderBoard = [[OKLeaderboard alloc] initFromJSON:[leaderBoardsJSON objectAtIndex:x]];
                 [leaderBoardsList addObject:leaderBoard];
             }
            completionHandler(leaderBoardsList, nil);
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Failed to get list of leaderboards: %@", error);
         completionHandler(nil, error);
     }];
    
    [operation start];
}

-(void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange WithCompletionhandler:(void (^)(NSArray* scores, NSError *error))completionHandler
{
    AFHTTPClient *OK_HTTPClient = [[OpenKit sharedInstance] httpClient];
    
    //Create a request and send it to OpenKit
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[OpenKit getApplicationID] forKey:@"app_key"];
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


    NSMutableURLRequest *request = [OK_HTTPClient requestWithMethod:@"GET" path:@"/scores" parameters:params];
    
    AFHTTPRequestOperation *operation =
    [OK_HTTPClient HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully got scores: %@", responseObject);
        
        NSArray *scoresJSON = (NSArray*)responseObject;
        int numScores = [scoresJSON count];
        
        NSMutableArray *scores = [[NSMutableArray alloc] initWithCapacity:numScores];
        
        for (int x = 0; x < numScores; x++) {
            OKScore *score = [[OKScore alloc] initFromJSON:[scoresJSON objectAtIndex:x]];
            [scores addObject:score];
            if (u && score.user.OKUserID == u.OKUserID) {
                NSLog(@"Current user's score is: %d", score.scoreValue);
            }
        }
        
        completionHandler(scores, nil);
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed to get scores");
        completionHandler(nil, error);
    }];
    
    [operation start];
}


@end
