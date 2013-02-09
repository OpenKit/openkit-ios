//
//  OKScore.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OKUser;
@interface OKScore : NSObject

@property (nonatomic) NSInteger OKScoreID;
@property (nonatomic) NSInteger scoreValue;
@property (nonatomic) NSInteger OKLeaderboardID;
@property (nonatomic, strong) OKUser *user;
@property (nonatomic) NSInteger scoreRank;

- (id)initFromJSON:(NSDictionary*)jsonDict;
- (void)submitScoreWithCompletionHandler:(void (^)(NSError *error))completionHandler;

@end
