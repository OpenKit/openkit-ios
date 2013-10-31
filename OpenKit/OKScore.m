//
//  OKScore.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScore.h"
#import "OKDBScore.h"
#import "OKDefines.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKHelper.h"
#import "OKLeaderboard.h"
#import "OKPrivate.h"


@implementation OKScore

+ (id)scoreWithLeaderboard:(OKLeaderboard*)leaderboard
{
    return [[OKScore alloc] initWithLeaderboard:leaderboard];
}


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
        if(![self configWithDictionary:dict])
            return NO;
    }
    return self;
}


- (id)initWithLeaderboard:(OKLeaderboard*)leaderboard
{
    NSParameterAssert(leaderboard);
    return [self initWithLeaderboardID:[leaderboard leaderboardID]];
}


- (id)initWithLeaderboardID:(NSInteger)index
{
    NSParameterAssert(index > 0);
    
    self = [super init];
    if (self) {
        self.leaderboardID = index;
    }
    return self;
}


- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    if(![dict isKindOfClass:[NSDictionary class]])
        return NO;
    NSParameterAssert(dict);

    self.rowIndex       = [OKHelper getIntFrom:dict key:@"row_id"];
    self.modifyDate     = [OKHelper getNSDateFrom:dict key:@"modify_date"];
    
    self.scoreID        = [OKHelper getIntFrom:dict key:@"id"];
    self.scoreValue     = [OKHelper getInt64From:dict key:@"value"];
    self.scoreRank      = [OKHelper getIntFrom:dict key:@"rank"];
    self.leaderboardID  = [OKHelper getIntFrom:dict key:@"leaderboard_id"];
    self.user           = [OKUser createUserWithDictionary:dict[@"user"]];
    self.displayString  = [OKHelper getNSStringFrom:dict key:@"display_string"];
    self.metadata       = [OKHelper getIntFrom:dict key:@"metadata"];
    
    return YES;
}


- (NSDictionary*)JSONDictionary
{
    return @{@"leaderboard_id": @(_leaderboardID),
             @"value": @(_scoreValue),
             @"metadata": @(_metadata),
             @"display_string": OK_NO_NIL([self scoreDisplayString])};
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


- (BOOL)isScoreBetter:(OKScore*)score
{
    return YES;
}


- (NSString*)scoreDisplayString
{
    if([self displayString])
        return _displayString;
    
    return [NSString stringWithFormat:@"%lld", [self scoreValue]];
}


- (NSString*)userDisplayString
{
    return [[self user] name];
}


- (NSString*)rankDisplayString
{
    return [NSString stringWithFormat:@"%ld", (long)[self scoreRank]];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"OKScore id: %ld, submitted: %d, value: %lld, leaderboard id: %ld, display string: %@, metadata: %ld", (long)[self scoreID], [self submitState], [self scoreValue], (long)[self leaderboardID], [self displayString], (long)[self metadata]];
}


#pragma mark - Class methods

+ (BOOL)shouldSubmit:(OKScore*)score
{
    return YES;
}


+ (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError *error))handler
{
    NSParameterAssert(score);
    
    [score setDbConnection:[OKDBScore sharedConnection]];
    
    if([score isSubmissible] && [OKScore shouldSubmit:score]) {
        [score syncWithDB];
        [OKScore resolveScore:score withCompletion:handler];
    }else if(handler)
        handler([OKError OKScoreNotSubmittedError]);
}


+ (void)resolveScore:(OKScore*)score withCompletion:(void (^)(NSError *error))handler
{
    [score setUser:[OKLocalUser currentUser]];
    if([score user] == nil) {
        if(handler)
            handler([OKError noOKUserErrorScoreCached]); // ERROR
        
        return;
    }
    
    [OKLeaderboard getLeaderboardWithID:[score leaderboardID]
                             completion:^(OKLeaderboard *leaderboard, NSError *error)
    {
        // private method, never call it manually
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
