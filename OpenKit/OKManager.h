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
