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

// Predefinitions
@protocol OKManagerDelegate;
@class OKUser;
@class OKLocalUser;
@class OKAuthProvider;

@interface OKManager : NSObject

+ (id)sharedManager;
+ (void)configureWithAppKey:(NSString*)appKey secretKey:(NSString*)secretKey;
+ (void)configureWithAppKey:(NSString*)appKey secretKey:(NSString*)secretKey endpoint:(NSString*)endpoint;
- (void)logoutCurrentUser;
- (void)registerToken:(NSData*)deviceToken;

@property(nonatomic, readonly) OKCrypto *cryptor;
@property(nonatomic, readonly) BOOL initialized;
@property(nonatomic, strong) NSString *leaderboardListTag;


// See OKManagerDelegate protocol, below.
@property (nonatomic, assign) id<OKManagerDelegate> delegate;

// Let's stop creating class helpers for getting / setting.  Instead, grab the sharedManager
// and set properties on that.  E.g.
//
//    OKManager *manager = [OKManager sharedManager];
//    manager.delegate   = anObject;
//    manager.endpoint   = "whatever";
//    manager.appKey     = "foo";
//    manager.secretKey  = "bar";
//

+ (NSString*)appKey;
+ (NSString*)endpoint;

+ (BOOL)handleOpenURL:(NSURL*)url;

- (void)loginWithProviderName:(NSString*)serviceName
               viewController:(UIViewController*)controller
                   completion:(void(^)(OKLocalUser *user, NSError *error))handler;

- (void)loginWithProvider:(OKAuthProvider*)provider
           viewController:(UIViewController*)controller
               completion:(void(^)(OKLocalUser *user, NSError *error))handler;

@end


#pragma mark - OKManagerDelegate Protocol

@protocol OKManagerDelegate <NSObject>
@optional

- (void)openkitDidLaunch:(OKManager*)manager;
- (void)openkitDidChangeStatus:(OKManager*)manager;
- (void)openkitHandledError:(NSError*)error source:(id)source;

@end

