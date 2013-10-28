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
#import "OKNotifications.h"
#import "OKFileUtil.h"


#define OK_LEADERBOARDS @"leaderboards.json"
static NSUInteger __lastUpdate = 0;
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


- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    self.name           = [OKHelper getNSStringFrom:dict key:@"name"];
    self.leaderboardID  = [OKHelper getIntFrom:dict key:@"id"];
    self.iconUrl        = [OKHelper getNSStringFrom:dict key:@"icon_url"];
    self.playerCount    = [OKHelper getIntFrom:dict key:@"player_count"];
    self.services       = [OKHelper getNSDictionaryFrom:dict key:@"services"];
    
    NSString *sortTypeString    = [OKHelper getNSStringFrom:dict key:@"sort_type"];
    if([sortTypeString isEqualToString:@"HighValue"]) {
        self.sortType = OKLeaderboardSortTypeHighValue;
    }else{
        self.sortType = OKLeaderboardSortTypeLowValue;
    }
    
    return (self.name && self.leaderboardID);
}


- (NSDictionary*)dictionary
{
    NSAssert(self.name, @"Name can not be nil.");
    
    return @{@"id": @(self.leaderboardID),
             @"name": self.name,
             @"icon_url": OK_NO_NIL(self.iconUrl),
             @"player_count": @(self.playerCount),
             @"services": OK_NO_NIL(self.services) };
}


- (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError* error))handler
{
    NSParameterAssert(score);
    
    // Posting NSNotification
    [[NSNotificationCenter defaultCenter] postNotificationName:OKScoreSubmittedNotification
                                                        object:self
                                                      userInfo:@{@"score": score}];
    
    
    //Create a request and send it to OpenKit
    NSDictionary *params = @{@"score": [score JSONDictionary]};
    
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
             
             // REVIEW: check error code. maybe we have to remove it
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


-(NSString*)getParamForTimeRange:(OKLeaderboardTimeRange)range
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


- (BOOL)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
                   pageNumber:(NSInteger)pageNum
                   completion:(void (^)(NSArray* scores, NSError *error))handler
{
    //Create a request and send it to OpenKit
    //Create the request parameters
    NSDictionary *params = @{@"leaderboard_id": @([self leaderboardID]),
                             @"page_num": @(pageNum),
                             @"num_per_page": @(NUM_SCORES_PER_PAGE),
                             @"leaderboard_range": [self getParamForTimeRange:timeRange] };
    
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/best_scores"
                  parameters:params
                  completion:^(id responseObject, NSError *error)
     {
         NSMutableArray *scores = nil;
         if(!error) {
             NSArray *scoresJSON = (NSArray*)responseObject;
             scores = [NSMutableArray arrayWithCapacity:[scoresJSON count]];
             
             for(id obj in scoresJSON) {
                 OKScore *score = [[OKScore alloc] initWithDictionary:obj];
                 [scores addObject:score];
             }
         } else {
             OKLogErr(@"Failed to get scores, with error: %@", error);
         }
         
         if(handler)
             handler(scores, error);
     }];
    
    return NO;
}


- (BOOL)getSocialScoresForTimeRange:(OKLeaderboardTimeRange)timeRange
                         completion:(void (^)(NSArray* scores, NSError *error))handler
{
    OKLocalUser *user = [OKLocalUser currentUser];
    if(!user) {
        if(handler)
            handler(nil, [OKError noOKUserError]);
        
        return YES;
    }
    
    [user syncWithCompletion:^(NSError *err) {
        
        //Create a request and send it to OpenKit
        //Create the request parameters
        NSDictionary *params = @{@"leaderboard_id": @([self leaderboardID]),
                                 @"leaderboard_range": [self getParamForTimeRange:timeRange] };
        
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
                 for(id obj in scoresJSON) {
                     
                     OKScore *score = [[OKScore alloc] initWithDictionary:obj];
                     [scores addObject:score];
                 }
                 
             } else {
                 NSLog(@"Failed to get scores, with error: %@", error);
             }
             if(handler)
                 handler(scores, error);
         }];
    }];
    
    return NO;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"OKLeaderboard name: %@ id: %ld sortType: %u iconURL: %@ player_count: %lu",
            self.name, (long)self.leaderboardID, self.sortType, self.iconUrl, (unsigned long)self.playerCount];
}


#pragma mark - Class methods

+ (BOOL)configWithDictionary:(NSDictionary*)dict
{
    if(!dict)
        return NO;
    
    NSArray *leaderBoardsJSON = dict[@"leaderboards"];
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:[leaderBoardsJSON count]];
    
    for(id obj in leaderBoardsJSON) {
        // if the leaderboard already exist in memory, we update it
        OKLeaderboard *leaderboard = nil;
        if(__leaderboards) {
            leaderboard = [OKLeaderboard leaderboardForID:[obj[@"id"] integerValue]];
            if(leaderboard)
                [leaderboard configWithDictionary:obj];
        }
        if(!leaderboard)
            leaderboard = [[OKLeaderboard alloc] initWithDictionary:obj];

        [tmp addObject:leaderboard];
    }
    __leaderboards = [NSArray arrayWithArray:tmp];
    __lastUpdate = [dict[@"last_update"] unsignedIntegerValue];
    
    return YES;
}


+ (void)loadFromCache
{
    NSString *path = [OKFileUtil localOnlyCachePath:OK_LEADERBOARDS];
    NSDictionary *dict = [OKFileUtil readSecureFile:path];
    [OKLeaderboard configWithDictionary:dict];
}


+ (void)save
{
    if([__leaderboards count] > 0) {
        NSMutableArray *leaderboards = [NSMutableArray arrayWithCapacity:[__leaderboards count]];
        for(OKLeaderboard *lb in __leaderboards)
            [leaderboards addObject:[lb dictionary]];
        
        NSDictionary *dict = @{@"last_update": @(__lastUpdate),
                               @"leaderboards": leaderboards };
        
        NSString *path = [OKFileUtil localOnlyCachePath:OK_LEADERBOARDS];
        [OKFileUtil writeOnFileSecurely:dict path:path];
    }
}


+ (NSArray*)leaderboards
{
    if(__leaderboards == nil) {
        OKLogErr(@"You should call [OKLeaderboard getLeaderboardsWithCompletion:] first.");
    }
    return __leaderboards;
}


+ (BOOL)getLeaderboardsWithCompletion:(void (^)(NSArray* leaderboards, NSError* error))handler
{
    if(__leaderboards) {
        if(handler)
            handler([self leaderboards], nil);
        
        return YES;
        
    }else{
        [self syncWithCompletion:^(NSError* error) {
            if(handler)
                handler([self leaderboards], error);
        }];
        return NO;
    }
}


+ (BOOL)getLeaderboardWithID:(NSInteger)leaderboardID
                  completion:(void (^)(OKLeaderboard *leaderboard, NSError *error))handler
{
    return [self getLeaderboardsWithCompletion:^(NSArray* leaderboards, NSError* error)
    {
        if(handler) {
            OKLeaderboard *lb = [OKLeaderboard leaderboardForID:leaderboardID];
            handler(lb, error);
        }
    }];
}


+ (OKLeaderboard*)leaderboardForID:(NSInteger)leaderboardID
{
    for(OKLeaderboard* leaderboard in [OKLeaderboard leaderboards]) {
        if(leaderboard.leaderboardID == leaderboardID)
            return leaderboard;
    }
    return nil;
}


+ (NSDictionary*)JSONDictionary
{
  return @{@"last_update": @(__lastUpdate),
           @"tag": [[OKManager sharedManager] leaderboardListTag] };
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
             [OKLeaderboard save];
             
         }else{
             OKLogErr(@"OpenKit: OKLeaderboard: Failed to get list of leaderboards: %@", error);
         }
         
         if(handler)
             handler(error);
     }];
}

@end
