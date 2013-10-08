//
//  OKScore.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScore.h"
#import "OKUserUtilities.h"
#import "OKUser.h"
#import "OKManager.h"
#import "OKNetworker.h"
#import "OKDefines.h"
#import "OKGameCenterUtilities.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKDBScore.h"
#import "OKHelper.h"
#import "OKUtils.h"
#import "OKLeaderboard.h"
#import "OKFacebookUtilities.h"
#import "OKChallenge.h"


@implementation OKScore

- (id)init
{
    self = [super init];
    if (self) {
        _scoreID = -1;
        _leaderboardID = -1;
    }
    return self;
}


- (id)initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        [self configWithDictionary:dict];
    }
    return self;
}


- (id)initWithLeaderboardID:(int)index
{
    self = [super init];
    if (self) {
        self.leaderboardID = index;
    }
    return self;
}


- (void)configWithDictionary:(NSDictionary*)dict
{
    self.rowIndex       = [OKHelper getIntSafeForKey:@"row_id" fromJSONDictionary:dict];
    self.modifyDate     = [OKHelper getNSDateSafeForKey:@"modify_date" fromJSONDictionary:dict];
    
    self.scoreID        = [OKHelper getIntSafeForKey:@"id" fromJSONDictionary:dict];
    self.scoreValue     = [OKHelper getInt64SafeForKey:@"value" fromJSONDictionary:dict];
    self.scoreRank      = [OKHelper getIntSafeForKey:@"rank" fromJSONDictionary:dict];
    self.leaderboardID  = [OKHelper getIntSafeForKey:@"leaderboard_id" fromJSONDictionary:dict];
    self.user           = [OKUserUtilities createOKUserWithJSONData:[dict objectForKey:@"user"]];
    self.displayString  = [OKHelper getNSStringSafeForKey:@"display_string" fromJSONDictionary:dict];
    self.metadata       = [OKHelper getIntSafeForKey:@"metadata" fromJSONDictionary:dict];
}


- (NSDictionary*)JSONDictionary
{
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] initWithCapacity:3];
    [paramDict setValue:[NSNumber numberWithInt:_leaderboardID] forKey:@"leaderboard_id"];
    [paramDict setValue:[NSNumber numberWithLongLong:_scoreValue] forKey:@"value"];
    [paramDict setValue:[_user OKUserID] forKey:@"user_id"];
    [paramDict setValue:[NSNumber numberWithInt:_metadata] forKey:@"metadata"];
    [paramDict setValue:[self scoreDisplayString] forKey:@"display_string"];
    
    return paramDict;
}


- (void)submitWithCompletion:(void (^)(NSError *error))completion
{
    [OKScore submitScore:self withCompletion:completion];
}


- (BOOL)isSubmissible
{
    return
        self.leaderboardID != -1 &&
        self.scoreValue != 0;
}


/** OKScoreProtocol Implementation **/
-(NSString*)scoreDisplayString
{
    if([self displayString])
        return _displayString;
    
    return [NSString stringWithFormat:@"%lld", [self scoreValue]];
}


-(NSString*)userDisplayString
{
    return [[self user] userNick];
}

-(NSString*)rankDisplayString {
    return [NSString stringWithFormat:@"%d", [self scoreRank]];
}

-(int)rank {
    return [self scoreRank];
}

-(void)setRank:(NSInteger)rank {
    [self setScoreRank:rank];
}

-(OKScoreSocialNetwork)socialNetwork
{
    if([[self user] fbUserID])
        return OKScoreSocialNetworkFacebook;
    //else if ([[self user] gameCenterID])
    //    return OKScoreSocialNetworkGameCenter;
    else
        return OKScoreSocialNetworkUnknown;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"OKScore id: %d, submitted: %d, value: %lld, leaderboard id: %d, display string: %@, metadata: %d", [self scoreID], [self submitState], [self scoreValue], [self leaderboardID], [self displayString], [self metadata]];
}



#pragma mark - Class methods

+ (BOOL)isScoreBetter:(OKScore*)score
{
    return YES;
}


+ (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError *error))handler
{
    [score setDbConnection:[OKDBScore sharedConnection]];
    
    if([score isSubmissible] && [OKScore isScoreBetter:score]) {
        [score syncWithDB];
        [OKScore resolveScore:score withCompletion:handler];
        
    }else if(handler)
        handler([OKError OKScoreNotSubmittedError]);
}


+ (void)resolveScore:(OKScore*)score withCompletion:(void (^)(NSError *error))handler
{
    [score setUser:[OKUser currentUser]];
    if([score user] == nil) {
        if(handler)
            handler([OKError noOKUserErrorScoreCached]); // ERROR
        
        return;
    }
    
    [OKLeaderboard getLeaderboardWithID:[score leaderboardID]
                         withCompletion:^(OKLeaderboard *leaderboard, NSError *error) {
        [leaderboard submitScore:score withCompletion:handler];
    }];
}


+ (void)resolveUnsubmittedScores
{
    // Removing
    NSArray *scores = [[OKDBScore sharedConnection] getUnsubmittedScores];
    
    for(OKScore *score in scores)
        [OKScore resolveScore:score withCompletion:nil];
}


+ (void)clearSubmittedScore
{
    [[OKDBScore sharedConnection] clearSubmittedScores];
}

@end
