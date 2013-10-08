//
//  OKScore.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKScoreProtocol.h"
#import "OKDBConnection.h"

@class OKUser;
@interface OKScore : OKDBRow<OKScoreProtocol>

@property (nonatomic, readwrite) NSInteger scoreID;
@property (nonatomic, readwrite) int64_t scoreValue;
@property (nonatomic, readwrite) NSInteger leaderboardID;
@property (nonatomic, strong) OKUser *user;
@property (nonatomic, readwrite) NSInteger scoreRank;
@property (nonatomic, readwrite) int metadata;
@property (nonatomic, strong) NSString *displayString;

- (id)initWithDictionary:(NSDictionary*)dict;
- (id)initWithLeaderboardID:(int)index;
- (NSDictionary*)JSONDictionary;
- (void)submitWithCompletion:(void (^)(NSError *error))completion;
- (BOOL)isSubmissible;

+ (void)resolveUnsubmittedScores;
+ (void)clearSubmittedScore;

@end
