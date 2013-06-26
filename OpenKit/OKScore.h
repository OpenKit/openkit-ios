//
//  OKScore.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKScoreProtocol.h"

@class OKUser;
@interface OKScore : NSObject<OKScoreProtocol>

@property (nonatomic) NSInteger OKScoreID;
@property (nonatomic) int64_t scoreValue;
@property (nonatomic) NSInteger OKLeaderboardID;
@property (nonatomic, strong) OKUser *user;
@property (nonatomic) NSInteger scoreRank;
@property (nonatomic) int metadata;
@property (nonatomic, strong) NSString *displayString;
@property (nonatomic, strong) NSString *gamecenterLeaderboardID;

- (id)initFromJSON:(NSDictionary*)jsonDict;
- (void)submitScoreWithCompletionHandler:(void (^)(NSError *error))completionHandler;
-(void)submitScoreToOpenKitAndGameCenter;
-(void)submitScoreToOpenKitAndGameCenterWithCompletionHandler:(void (^)(NSError *error))completionHandler;

-(void)setRank:(NSInteger)rank;

@end
