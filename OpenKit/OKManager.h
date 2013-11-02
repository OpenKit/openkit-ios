//
//  OKManager.h
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OKCrypto.h"
#import "OKUser.h"
#import "OKAuth.h"


@interface OKClient : NSObject

@property(nonatomic, strong) NSString *host;
@property(nonatomic, strong) NSString *consumerKey;
@property(nonatomic, strong) NSString *consumerSecret;

- (BOOL)isValid;

@end


#pragma mark - OKManagerDelegate Protocol

@class OKManager;
@protocol OKManagerDelegate <NSObject>
@optional

- (void)openkitDidLaunch:(OKManager*)manager;
- (void)openkitDidChangeStatus:(OKManager*)manager;
- (void)openkitHandledError:(NSError*)error source:(id)source;

@end


#pragma mark - OKManager

@interface OKManager : NSObject

@property(nonatomic, readonly) OKClient *client;
@property(nonatomic, readonly) OKCrypto *cryptor;
@property(nonatomic, readonly) BOOL initialized;
@property(nonatomic, strong) NSString *leaderboardListTag;
@property(nonatomic, assign) id<OKManagerDelegate> delegate;


+ (id)sharedManager;
+ (void)configureWithAppKey:(NSString*)appKey secretKey:(NSString*)secretKey;
+ (void)configureWithAppKey:(NSString*)appKey secretKey:(NSString*)secretKey host:(NSString*)endpoint;
+ (BOOL)handleOpenURL:(NSURL*)url;

- (void)logoutCurrentUser;
- (void)registerToken:(NSData*)deviceToken;

- (void)loginWithProviderName:(NSString*)serviceName
               viewController:(UIViewController*)controller
                   completion:(void(^)(OKLocalUser *user, NSError *error))handler;

- (void)loginWithProvider:(OKAuthProvider*)provider
           viewController:(UIViewController*)controller
               completion:(void(^)(OKLocalUser *user, NSError *error))handler;

@end
