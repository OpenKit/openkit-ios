//
//  OKManager.h
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OKUser;
@interface OKManager : NSObject

+ (id)sharedManager;
- (void)saveCurrentUser:(OKUser *)aCurrentUser;
- (void)logoutCurrentUser;

@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *secretKey;
@property (nonatomic, strong) NSString *endpoint;

@property (nonatomic) BOOL hasShownFBLoginPrompt;
@property (nonatomic, strong) NSString *leaderboardListTag;

// See OKManagerDelegate protocol, below.
@property (nonatomic, assign) id delegate;

// Let's stop creating class helpers for getting / setting.  Instead, grab the sharedManager
// and set properties on that.  E.g.
//
//    OKManager *manager = [OKManager sharedManager];
//    manager.delegate   = anObject;
//    manager.endpoint   = "whatever";
//    manager.appKey     = "foo";
//    manager.secretKey  = "bar";
//
+ (void)setAppKey:(NSString *)appKey;
+ (NSString *)appKey;
+ (void)setEndpoint:(NSString *)endpoint;
+ (NSString *)endpoint;
+ (void)setSecretKey:(NSString *)secretKey;
+ (NSString *)secretKey;

+ (BOOL)handleOpenURL:(NSURL*)url;
+ (void)handleDidBecomeActive;
+ (void)handleWillTerminate;

@end

#pragma mark - OKManagerDelegate Protocol
@protocol OKManagerDelegate <NSObject>
@optional

- (void)openkitManagerWillShowDashboard:(OKManager *)manager;
- (void)openkitManagerDidShowDashboard:(OKManager *)manager;
- (void)openkitManagerWillHideDashboard:(OKManager *)manager;
- (void)openkitManagerDidHideDashboard:(OKManager *)manager;

@end

