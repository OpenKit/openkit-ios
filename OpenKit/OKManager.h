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


+ (void)setApplicationID:(NSString *)appID;
+ (NSString*)getApplicationID;
+ (void)setEndpoint:(NSString *)endpoint;
+ (NSString *)getEndpoint;
+ (void)initializeWithAppID:(NSString *)appID;

+ (BOOL)handleOpenURL:(NSURL*)url;
+ (void)handleDidBecomeActive;
+ (void)handleWillTerminate;

@end
