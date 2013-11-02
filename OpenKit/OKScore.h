//
//  OKScore.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKDBConnection.h"
#import "OKLeaderboard.h"
#import "OKUser.h"


@interface OKScore : OKDBRow

@property(nonatomic, readwrite) NSInteger scoreID;
@property(nonatomic, readwrite) int64_t scoreValue;
@property(nonatomic, readwrite) NSInteger leaderboardID;
@property(nonatomic, strong) OKUser *user;
@property(nonatomic, readwrite) NSInteger scoreRank;
@property(nonatomic, readwrite) NSInteger metadata;
@property(nonatomic, strong) NSString *displayString;

+ (id)scoreWithLeaderboard:(OKLeaderboard*)leaderboard;
- (id)initWithLeaderboard:(OKLeaderboard*)leaderboard;
- (id)initWithDictionary:(NSDictionary*)dict;
- (id)initWithLeaderboardID:(NSInteger)index;
- (NSDictionary*)JSONDictionary;
- (void)submitWithCompletion:(void (^)(NSError *error))completion;
- (BOOL)isSubmissible;

- (NSString*)scoreDisplayString;
- (NSString*)userDisplayString;
- (NSString*)rankDisplayString;


+ (void)resolveUnsubmittedScores;
+ (void)clearSubmittedScore;

@end
