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
#import "OKGameCenterUtilities.h"
#import "OKError.h"
#import "OKGKScoreWrapper.h"
#import "OKMacros.h"
#import "OKFacebookUtilities.h"

@implementation OKLeaderboard

@synthesize OKLeaderboard_id, OKApp_id, name, in_development, sortType, icon_url, playerCount, gamecenter_id;

- (id)initFromJSON:(NSDictionary*)jsonDict
{
    if ((self = [super init])) {
        NSString *sortTypeString    = (NSString*)[jsonDict objectForKey:@"sort_type"];

        self.name                   = [jsonDict objectForKey:@"name"];
        self.OKLeaderboard_id       = [[jsonDict objectForKey:@"id"] integerValue];
        self.OKApp_id               = [[jsonDict objectForKey:@"app_id"] integerValue];
        self.in_development         = [[jsonDict objectForKey:@"in_development"] boolValue];
        self.sortType               = ([sortTypeString isEqualToString:@"HighValue"]) ? OKLeaderboardSortTypeHighValue : OKLeaderboardSortTypeLowValue;
        self.icon_url               = [jsonDict objectForKey:@"icon_url"];
        self.playerCount            = [[jsonDict objectForKey:@"player_count"] integerValue];
        self.gamecenter_id          = [jsonDict objectForKey:@"gamecenter_id"];

        //_timeRange = OKLeaderboardTimeRangeOneDay;
    }

    return self;
}

- (NSString *)playerCountString
{
    return [NSString stringWithFormat:@"%d Players", playerCount];
}

+ (void)getLeaderboardsWithCompletionHandler:(void (^)(NSArray* leaderboards, int playerCount, NSError* error))completionHandler
{
    // OK NETWORK REQUEST
    [OKNetworker getFromPath:@"/leaderboards" parameters:nil
                     handler:^(id responseObject, NSError *error)
     {
         int maxPlayerCount = 0;
         
         NSMutableArray *leaderboards = nil;
         if(!error) {
             NSLog(@"Successfully got list of leaderboards");
             //NSLog(@"Leaderboard response is: %@", responseObject);
             NSArray *leaderBoardsJSON = (NSArray*)responseObject;
             leaderboards = [NSMutableArray arrayWithCapacity:[leaderBoardsJSON count]];
             
             
             
             for(id obj in leaderBoardsJSON) {
                 OKLeaderboard *leaderBoard = [[OKLeaderboard alloc] initFromJSON:obj];
                 [leaderboards addObject:leaderBoard];
                 
                 if([leaderBoard playerCount] > maxPlayerCount)
                     maxPlayerCount = [leaderBoard playerCount];
             }
         }else{
             NSLog(@"Failed to get list of leaderboards: %@", error);
         }
         completionHandler(leaderboards, maxPlayerCount, error);
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

-(BOOL)showGlobalScoresFromGameCenter
{
    //TODO remove this temporary workaround
    
    // If gamecenter is available and this leaderboard has a gamecenter ID, get global scores from gamecenter
    
    // For the time being, with Game Center only returning a single score (!) we're going to default
    // to OpenKit for global scores.
#if 0
    if(self.gamecenter_id && [OKGameCenterUtilities gameCenterIsAvailable]) {
        
        return YES;
    }
    else {
#endif
        return NO;
}

// Get global scores from either GameCenter or OpenKit depending on GameCenter availability
// Takes a page number of scores and converts to range for GameCenter
-(void)getGlobalScoresWithPageNum:(int)pageNum withCompletionHandler:(void (^)(NSArray *scores, NSError *error))completionHandler
{
    //TODO remove this temporary workaround
    //[self getScoresForTimeRange:OKLeaderboardTimeRangeAllTime forPageNumber:pageNum WithCompletionhandler:completionHandler];
    //return;
    
    // If gamecenter is available and this leaderboard has a gamecenter ID, get global scores from gamecenter

    // For the time being, with Game Center only returning a single score (!) we're going to default
    // to OpenKit for global scores.
#if 0
    if(self.gamecenter_id && [OKGameCenterUtilities gameCenterIsAvailable]) {
        
        NSRange scoreRange = NSMakeRange((pageNum-1)*NUM_SCORES_PER_PAGE+1, NUM_SCORES_PER_PAGE);
        
        [self getScoresFromGameCenterWithRange:scoreRange withPlayerScope:GKLeaderboardPlayerScopeGlobal withCompletionHandler:completionHandler];
    }
    else {
#endif
        [self getScoresForTimeRange:OKLeaderboardTimeRangeAllTime forPageNumber:pageNum WithCompletionhandler:completionHandler];
#if 0
    }
#endif
}

//Get friends scores from gamecenter, retrieves up to 100 scores (hardcoded)
-(void)getGameCenterFriendsScoreswithCompletionHandler:(void (^)(NSArray *scores, NSError *error))completionHandler
{
    [self getScoresFromGameCenterWithRange:NSMakeRange(1, 100) withPlayerScope:GKLeaderboardPlayerScopeFriendsOnly withCompletionHandler:^(NSArray *scores, NSError *error) {
        completionHandler(scores, error);
    }];
}


// Get global scores from gamecenter. Range must start from 1-25
-(void)getScoresFromGameCenterWithRange:(NSRange)scoreRange withPlayerScope:(GKLeaderboardPlayerScope)playerScope withCompletionHandler:(void (^)(NSArray *scores, NSError *error))completionHandler
{
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
    
    if(![self gamecenter_id]) {
        completionHandler(nil, [OKError noGameCenterIDError]);
        return;
    }
    
    if(leaderboardRequest != nil)
    {
        leaderboardRequest.playerScope = playerScope;
        leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
        leaderboardRequest.category = [self gamecenter_id];
        leaderboardRequest.range = scoreRange;
        
        [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            if (error != nil)
            {
                NSLog(@"Error getting gamecenter scores: %@", error);
                completionHandler(nil, error);
            }
            else if (scores != nil)
            {
                OKLog(@"Received %d scores from GameCenter", [scores count]);
                
                //Get the player's local score for this leaderboard if available
                [self setLocalPlayerScore:leaderboardRequest.localPlayerScore];
                //OKLog(@"Local player score: %@", leaderboardRequest.localPlayerScore);
                
                // Get the players for the scores
                
                //Create an array to list the player identifiers
                NSMutableArray *playerIDs = [[NSMutableArray alloc] initWithCapacity:[scores count]];
                
                for(int x = 0; x < [scores count]; x++){
                    GKScore *score = [scores objectAtIndex:x];
                    [playerIDs addObject:[score playerID]];
                }
                
                // Get the player info for each score
                [GKPlayer loadPlayersForIdentifiers:playerIDs withCompletionHandler:^(NSArray *players, NSError *error) {
                    if (error != nil){
                        // Got scores, but couldn't get player info for scores
                        OKLog(@"Error getting player info from GameCenter scores");
                        completionHandler(nil,error);
                    }
                    else if (players != nil){
                        
                        OKLog(@"Received player info from GameCenter for %d players", [players count]);
                        
                        NSMutableArray *gkScores = [[NSMutableArray alloc] initWithCapacity:[players count]];
                        
                        // Process the array of GKPlayer objects.
                        for(int x = 0; x< [players count]; x++)
                        {
                            //Create a score wrapper that contains the GKSCore and the GKPLayer for that score
                            OKGKScoreWrapper *gkScoreWrapper = [[OKGKScoreWrapper alloc] init];
                            [gkScoreWrapper setScore:[scores objectAtIndex:x]];
                            [gkScoreWrapper setPlayer:[players objectAtIndex:x]];
                            [gkScores addObject:gkScoreWrapper];
                        }
                        
                        completionHandler(gkScores, nil);
                    }
                    else {
                        completionHandler(nil, nil);
                    }
                }];
                
                
            }
            else{
                // This could also be 0 scores returned
                completionHandler(nil, nil);
            }
        }];
    }
}

-(void)getScoresForTimeRange:(OKLeaderboardTimeRange)timeRange WithCompletionhandler:(void (^)(NSArray *, NSError *))completionHandler
{
    [self getScoresForTimeRange:timeRange forPageNumber:1 WithCompletionhandler:completionHandler];
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
             NSLog(@"Successfully got scores");
             
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


-(void)getFacebookFriendsScoresWithFacebookFriends:(NSArray*)friends withCompletionHandler:(void (^)(NSArray *scores, NSError *error))completionHandler
{
    
    //Create a request and send it to OpenKit
    //Create the request parameters
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[NSNumber numberWithInt:[self OKLeaderboard_id]] forKey:@"leaderboard_id"];
    [params setValue:friends forKey:@"fb_friends"];
    
    // OK NETWORK REQUEST
    [OKNetworker postToPath:@"/best_scores/social" parameters:params
                    handler:^(id responseObject, NSError *error)
     {
         NSMutableArray *scores = nil;
         if(!error) {
             NSLog(@"Successfully got FB friends scores");
             
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


-(void)getFacebookFriendsScoresWithCompletionHandler:(void (^)(NSArray *scores, NSError *error))completionHandler
{
    // Get the facebook friends list, then get scores from OpenKit with fb friends filter

    [OKFacebookUtilities getListOfFriendsForCurrentUserWithCompletionHandler:^(NSArray *friends, NSError *error) {
        if(error) {
            completionHandler(nil, error);
        } else if(friends){
            [self getFacebookFriendsScoresWithFacebookFriends:friends withCompletionHandler:completionHandler];
        }
        else {
            completionHandler(nil, [OKError unknownFacebookRequestError]);
        }
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

-(void)getUsersTopScoreFromGameCenterWithCompletionHandler:(void (^)(OKGKScoreWrapper *score, NSError *error))completionHandler
{
    if(![OKGameCenterUtilities gameCenterIsAvailable]) {
        completionHandler(nil, [OKError gameCenterNotAvailableError]);
        return;
    }
    
    if(![self gamecenter_id]) {
        completionHandler(nil, [OKError noGameCenterIDError]);
        return;
    }
    
    NSString *localPlayerID = [[GKLocalPlayer localPlayer] playerID];
    
    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:localPlayerID]];
    
    leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
    leaderboardRequest.category = [self gamecenter_id];
    
    if(leaderboardRequest !=  nil){
        
        [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
            if(error != nil) {
                completionHandler(nil, error);
            } else if (scores != nil)
            {
                GKScore *score = [scores objectAtIndex:0];
                
                OKGKScoreWrapper *wrapper = [[OKGKScoreWrapper alloc] init];
                [wrapper setScore:score];
                [wrapper setPlayer:[GKLocalPlayer localPlayer]];
                
                completionHandler(wrapper, nil);
            } else
            {
                completionHandler(nil, [OKError unknownGameCenterError]);
            }
        }];
    }
    else {
        completionHandler(nil, [OKError unknownGameCenterError]);
    }
}


@end
