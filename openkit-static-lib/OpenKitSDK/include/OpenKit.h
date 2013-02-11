//
//  OpenKit.h
//  OKClient
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "OKScore.h"
#import "OKUser.h"
#import "OKLeaderboard.h"
#import "OKLeaderboardsViewController.h"
#import "OKUserProfileImageView.h"
#import "OKLoginView.h"
#import "OKCloud.h"


@interface OpenKit : NSObject

@property (nonatomic, strong) AFHTTPClient *httpClient;

+ (id)sharedInstance;
- (void)saveCurrentUser:(OKUser *)aCurrentUser;
- (void)logoutCurrentUser;


+(void)setApplicationID:(NSString *)appID;
+(NSString*)getApplicationID;
+(void)initializeWithAppID:(NSString *)appID;

+(BOOL)handleOpenURL:(NSURL*)url;
+(void)handleDidBecomeActive;
+(void)handleWillTerminate;

@end
