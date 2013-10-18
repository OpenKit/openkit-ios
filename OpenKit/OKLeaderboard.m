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
#import "OKHelper.h"
#import "OKNetworker.h"
#import "OKScore.h"
#import "OKError.h"
#import "OKMacros.h"
#import "OKFacebookUtilities.h"
#import "OKDBScore.h"
#import "OKNotifications.h"


static NSArray *__leaderboards = nil;
static NSString *DEFAULT_LEADERBOARD_LIST_TAG = @"v1";

@implementation OKLeaderboard

- (id)initWithDictionary:(NSDictionary*)dict
{
    if ((self = [super init])) {
        [self configWithDictionary:dict];
    }
    return self;
}


- (void)configWithDictionary:(NSDictionary*)dict
{
    self.name           = [OKHelper getNSStringFrom:dict key:@"name"];
    self.leaderboardID  = [[OKHelper getNSNumberFrom:dict key:@"id"] integerValue];
    self.iconUrl        = [OKHelper getNSStringFrom:dict key:@"icon_url"];
    self.playerCount    = [[OKHelper getNSNumberFrom:dict key:@"player_count"] integerValue];
    self.services       = [OKHelper getNSDictionaryFrom:dict key:@"services"];
    
    NSString *sortTypeString    = [OKHelper getNSStringFrom:dict key:@"sort_type"];
    if([sortTypeString isEqualToString:@"HighValue"]) {
        self.sortType = OKLeaderboardSortTypeHighValue;
    }else{
        self.sortType = OKLeaderboardSortTypeLowValue;
    }
}
}


- (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError* error))handler
{
    
    //    // If the error code returned is in the 400s, delete the score from the cache
    //    int errorCode = [OKNetworker getStatusCodeFromAFNetworkingError:error];
    //    if(errorCode >= 400 && errorCode <= 500) {
    //        OKLog(@"Deleted cached score because of error code: %d",errorCode);
    //        [self deleteScore:score];
    //    }
    //    OKLog(@"Failed to submit cached score");
    //
    
    // Posting NSNotification
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:score forKey:@"score"];
    [[NSNotificationCenter defaultCenter] postNotificationName:OKScoreSubmittedNotification
                                                        object:self
                                                      userInfo:userInfo];
    
    
    //Create a request and send it to OpenKit
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            [score JSONDictionary], @"score", nil];
    
    [OKNetworker postToPath:@"/scores"
                 parameters:params
                 completion:^(id responseObject, NSError *error)
     {
         if(!error) {
             OKLog(@"Successfully posted score to OpenKit: %@", self);
             [score setSubmitState:kOKSubmitted];

         }else{
             OKLog(@"Failed to post score to OpenKit: %@",self);
             OKLog(@"Error: %@", error);
             [score setSubmitState:kOKNotSubmitted];
             
             // If the user is unsubscribed to the app, log out the user. REVIEW
             // [OKUserUtilities checkIfErrorIsUnsubscribedUserError:error];
         }
         [score syncWithDB];
         
         if(handler)
             handler(error);
         
         // REVIEW THIS
         //OKScore *previousScore = [[OKScoreCache sharedCache] previousSubmittedScore];
         //[[OKScoreCache sharedCache] setPreviousSubmittedScore:nil];
         
         // If there was no error, try issuing a push challenge
         //         if(!error) {
         //             [OKChallenge sendPushChallengewithScorePostResponseJSON:responseObject withPreviousScore:previousScore];
         //         }
         
     }];
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


- (void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
                  pageNumber:(int)pageNum
                  completion:(void (^)(NSArray* scores, NSError *error))handler
{
    //Create a request and send it to OpenKit
    //Create the request parameters
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInt:[self leaderboardID]], @"leaderboard_id",
                            [NSNumber numberWithInt:pageNum], @"page_num",
                            [NSNumber numberWithInt:NUM_SCORES_PER_PAGE], @"num_per_page",
                            [self getParamForLeaderboardTimeRange:timeRange], @"leaderboard_range", nil];
    
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/best_scores"
                  parameters:params
                  completion:^(id responseObject, NSError *error)
     {
         NSMutableArray *scores = nil;
         if(!error) {
             //OKLog(@"Successfully got scores");
             NSArray *scoresJSON = (NSArray*)responseObject;
             scores = [NSMutableArray arrayWithCapacity:[scoresJSON count]];
             
             for(id obj in scoresJSON) {
                 OKScore *score = [[OKScore alloc] initWithDictionary:obj];
                 [scores addObject:score];
             }
         } else {
             OKLog(@"Failed to get scores, with error: %@", error);
         }
         
         if(handler)
             handler(scores, error);
     }];
}


- (void)getSocialScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
                         completion:(void (^)(NSArray* scores, NSError *error))handler
{
    //Create a request and send it to OpenKit
    //Create the request parameters
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:
                            [NSNumber numberWithInt:[self leaderboardID]], @"leaderboard_id",
                            [self getParamForLeaderboardTimeRange:timeRange], @"leaderboard_range", nil];
    
    // OK NETWORK REQUEST
    [OKNetworker postToPath:@"/best_scores/social"
                 parameters:params
                 completion:^(id responseObject, NSError *error)
     {
         NSMutableArray *scores = nil;
         if(!error) {
             OKLog(@"Successfully got FB friends scores");
             
             NSArray *scoresJSON = (NSArray*)responseObject;
             scores = [NSMutableArray arrayWithCapacity:[scoresJSON count]];
             
             // For now, just storing a list of friend OK Ids.
             NSMutableArray *arr = [[NSMutableArray alloc] init];
             
             for(id obj in scoresJSON) {
                 
                 OKScore *score = [[OKScore alloc] initWithDictionary:obj];
                 [arr addObject:[[score user] userID]];
                 [scores addObject:score];
             }
             
         } else {
             NSLog(@"Failed to get scores, with error: %@", error);
         }
         if(handler)
         handler(scores, error);
     }];
}


- (NSSortDescriptor*)getSortDescriptor
{
    NSSortDescriptor *sortDescriptor;
    
    if([self sortType] == OKLeaderboardSortTypeHighValue){
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scoreValue" ascending:NO];
    } else {
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scoreValue" ascending:YES];
    }
    
    return sortDescriptor;
}


- (NSArray*)sortScoresBasedOnLeaderboardType:(NSArray*)scores
{
    NSSortDescriptor *sortDescriptor = [self getSortDescriptor];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [scores sortedArrayUsingDescriptors:sortDescriptors];
    return sortedArray;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"OKLeaderboard name: %@ id: %d app_id: %d gamecenter_id: %@ sortType: %u iconURL: %@ player_count: %d", self.name, self.leaderboardID, self.OKApp_id, self.gamecenterID, self.sortType, self.iconUrl, self.playerCount];
}


#pragma mark - Class methods

+ (void)configWithDictionary:(NSArray*)dict
{
    if(!dict)
        return;
    
    NSArray *leaderBoardsJSON = dict;
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:[leaderBoardsJSON count]];
    
    for(id obj in leaderBoardsJSON) {
        // if the leaderboard already exist in memory, we update it
        OKLeaderboard *leaderboard = nil;
        if(__leaderboards) {
            leaderboard = [OKLeaderboard leaderboardForID:[[obj objectForKey:@"id"] integerValue]];
            if(leaderboard)
                [leaderboard configWithDictionary:obj];
        }
        if(!leaderboard)
            leaderboard = [[OKLeaderboard alloc] initWithDictionary:obj];

        [tmp addObject:leaderboard];
    }
    __leaderboards = [NSArray arrayWithArray:tmp];
}


+ (NSArray*)leaderboards
{
    if(__leaderboards == nil) {
        OKLogErr(@"You should call [OKLeaderboard getLeaderboardsWithCompletion:] first.");
    }
    return __leaderboards;
}


+ (void)getLeaderboardsWithCompletion:(void (^)(NSArray* leaderboards, NSError* error))handler
{
    if(!__leaderboards) {
        [self syncWithCompletion:^(NSError* error) {
            if(handler)
                handler([self leaderboards], error);
        }];
        
    }else if(handler)
        handler([self leaderboards], nil);
}


+ (void)getLeaderboardWithID:(int)leaderboardID withCompletion:(void (^)(OKLeaderboard *leaderboard, NSError *error))handler
{
    [self getLeaderboardsWithCompletion:^(NSArray* leaderboards, NSError* error) {
        if(handler) {
            OKLeaderboard *lb = [OKLeaderboard leaderboardForID:leaderboardID];
            handler(lb, error);
        }
    }];
}


+ (OKLeaderboard*)leaderboardForID:(int)leaderboardID
{
    for(OKLeaderboard* leaderboard in [OKLeaderboard leaderboards]) {
        if(leaderboard.leaderboardID == leaderboardID)
            return leaderboard;
    }
    return nil;
}


+ (NSDictionary*)JSONDictionary
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          //_lastUpdate, @"last_update",
                          [[OKManager sharedManager] leaderboardListTag], @"tag",
                          nil];
    return dict;
}


+ (void)syncWithCompletion:(void (^)(NSError* error))handler
{
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/leaderboards"
                  parameters:[OKLeaderboard JSONDictionary]
                  completion:^(id responseObject, NSError *error)
     {
         if(!error) {
             OKLog(@"OpenKit: OKLeaderboard: Successfully got list of leaderboards.");
             [OKLeaderboard configWithDictionary:responseObject];
             
         }else{
             OKLogErr(@"OpenKit: OKLeaderboard: Failed to get list of leaderboards: %@", error);
         }
         
         if(handler)
             handler(error);
     }];
}

@end
