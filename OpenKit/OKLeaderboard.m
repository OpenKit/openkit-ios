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
static NSArray *__leaderboards = nil;
static NSString *DEFAULT_LEADERBOARD_LIST_TAG = @"v1";

@implementation OKLeaderboard

- (id)initWithDictionary:(NSDictionary*)dict
{
    if ((self = [super init])) {
        if(![self configWithDictionary:dict])
            return NO;
    }
    return self;
}


- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    if(![dict isKindOfClass:[NSDictionary class]])
        return NO;

    self.name           = OK_CHECK(dict[@"name"], NSString);
    self.iconUrl        = OK_CHECK(dict[@"icon_url"], NSString);
    self.services       = OK_CHECK(dict[@"services"], NSDictionary);
    self.leaderboardID  = [OKHelper getIntFrom:dict key:@"id"];
    self.playerCount    = [OKHelper getIntFrom:dict key:@"player_count"];

    NSString *sortTypeString = OK_CHECK(dict[@"sort_type"], NSString);
    if([sortTypeString isEqualToString:@"HighValue"]) {
        self.sortType = OKLeaderboardSortTypeHighValue;
    }else{
        self.sortType = OKLeaderboardSortTypeLowValue;
    }
    
    return (self.leaderboardID && self.name);
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
                 completion:^(OKResponse *response)
     {
         NSError *error = [response error];
         if(!error) {
             OKLogInfo(@"OKLeaderboard: Successfully posted score to OpenKit: %@", score);
             [score setSubmitState:kOKSubmitted];
             
         }else{
             OKLogErr(@"OKLeaderboard: Failed to post score to OpenKit");
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
                  completion:^(OKResponse *response)
     {
         NSError *error = [response error];
         NSMutableArray *scores = nil;
         if(!error) {

             id json = [response jsonObject];
             if([json isKindOfClass:[NSArray class]]) {
                 NSArray *scoresJSON = (NSArray*)json;
                 scores = [NSMutableArray arrayWithCapacity:[scoresJSON count]];

                 for(id obj in scoresJSON) {
                     OKScore *score = [[OKScore alloc] initWithDictionary:obj];
                     [scores addObject:score];
                 }
             }else{
                 // REVIEW
                 error = [OKError unknownError];
             }
         } else {

             OKLogErr(@"OKLeaderboard: Error getting global scores.");
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
                     completion:^(OKResponse *response)
         {
             NSError *error = [response error];
             NSMutableArray *scores = nil;
             if(!error) {
                 OKLogInfo(@"OKLeaderboard: Successfully got FB friends scores");

                 id json = [response jsonObject];
                 if([json isKindOfClass:[NSArray class]]) {
                     NSArray *scoresJSON = (NSArray*)json;
                     scores = [NSMutableArray arrayWithCapacity:[scoresJSON count]];
                     for(id obj in scoresJSON) {

                         OKScore *score = [[OKScore alloc] initWithDictionary:obj];
                         if(!score)
                             [scores addObject:score];
                         else
                             OKLogErr(@"OKLeaderboard: Error creating OKScore from: %@", obj);
                     }
                 }else{
                     // REVIEW
                     error = [OKError unknownError];
                 }
                 
             } else {
                 OKLogErr(@"OKLeaderboard: Failed to get scores.");
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

+ (BOOL)configWithArray:(NSArray*)leaderboards
{
    if(![leaderboards isKindOfClass:[NSArray class]])
        return NO;
    
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:[leaderboards count]];
    
    for(id obj in leaderboards) {
        // if the leaderboard already exist in memory, we update it
        OKLeaderboard *leaderboard = nil;
        if(__leaderboards) {
            leaderboard = [OKLeaderboard leaderboardForID:[obj[@"id"] integerValue]];
            if(leaderboard)
                [leaderboard configWithDictionary:obj];
        }
        if(!leaderboard)
            leaderboard = [[OKLeaderboard alloc] initWithDictionary:obj];

        if(leaderboard)
            [tmp addObject:leaderboard];
        else
            OKLogErr(@"OKLeaderboard: Error creating leaderboard from: %@", obj);
    }
    __leaderboards = [NSArray arrayWithArray:tmp];
    
    return YES;
}


+ (void)loadFromCache
{
    NSString *path = [OKFileUtil localOnlyCachePath:OK_LEADERBOARDS];
    NSArray *archive = [OKFileUtil readSecureFile:path];
    [self configWithArray:archive];
}


+ (void)save
{
    if([__leaderboards count] > 0) {
        NSMutableArray *leaderboards = [NSMutableArray arrayWithCapacity:[__leaderboards count]];
        for(OKLeaderboard *lb in __leaderboards)
            [leaderboards addObject:[lb dictionary]];

        NSString *path = [OKFileUtil localOnlyCachePath:OK_LEADERBOARDS];
        [OKFileUtil writeOnFileSecurely:leaderboards path:path];
    }
}


+ (NSArray*)leaderboards
{
    if(__leaderboards == nil) {
        OKLogErr(@"OKLeaderboard: You should call [OKLeaderboard getLeaderboardsWithCompletion:] first.");
    }
    return __leaderboards;
}


+ (BOOL)getLeaderboardsWithCompletion:(void (^)(NSArray* leaderboards, NSError* error))handler
{
    if(__leaderboards) {
        if(handler)
            handler(__leaderboards, nil);
        
        return YES;
        
    }else{
        [self syncWithCompletion:^(NSError* error) {
            if(handler)
                handler(__leaderboards, error);
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
            if(!lb && !error)
                error = [OKError unknownError];
            
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


+ (void)syncWithCompletion:(void (^)(NSError* error))handler
{
    // OK NETWORK REQUEST
    NSDictionary *params = @{@"tag": [[OKManager sharedManager] leaderboardListTag] };
    [OKNetworker getFromPath:@"/leaderboards"
                  parameters:params
                  completion:^(OKResponse *response)
     {
         NSError *error = [response error];
         if(!error) {
             if([self configWithArray:[response jsonObject]]) {
                 OKLogInfo(@"OKLeaderboard: Successfully got list of leaderboards.");
                 [self save];
             }else{
                 OKLogErr(@"OKLeaderboard: Error creating leaderboards from %@", [response jsonObject]);
             }
             
         }else{
             OKLogErr(@"OKLeaderboard: Failed to get list of leaderboards.");
         }
         
         if(handler)
             handler(error);
     }];
}

@end
