//
//  OKAuth.h
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "OKAuth.h"

@class OKAuthRequest;
@class OKAuthProfile;
@class OKAuthProvider;


@protocol OKAuthPluginProtocol
@required

+ (OKAuthProvider*)inject;
+ (OKAuthProvider*)sharedInstance;

+ (NSString*)serviceName;

//! Returns if the authentication services are available.
//! e.g. GameCenter can't provide authentication until iOS7.0
+ (BOOL)isUIVisible;

//! Returns if the session is already open.
//! This method should NOT try to open it.
+ (BOOL)isSessionOpen;

//! Do not call this directly.  This method is called internally by OKManager.
//! Your implementation of -start must:
//! - Try to open the session without making the user login, ie. doesn't display UI.
//! - Start handling any related event from the service like state changes (logged in, logged out) and errors.
//! - Post a notification (OKAuthProviderUpdatedNotification) each state change.
//! - Return YES if the session was opened synchronously.
+ (BOOL)start;

//! This method can be called directly from the developer's code.
//! If the controller is valid and the session is not open yet, this method should display the UI needed for login.
//! Return YES if the session was opened synchronously.
+ (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler;


//! Called internally to get an valid OK Auth Request,
//! we need this to login into openkit and get an openkit user ID.
+ (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler;

//! This method should:
//! - Try to close the session.
//! - Try remove any cached data.
+ (void)logoutAndClear;


+ (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler;
+ (BOOL)handleOpenURL:(NSURL *)url;
+ (void)handleDidBecomeActive;
+ (void)handleWillTerminate;

@end



@interface OKAuthPluginBase : NSObject<OKAuthPluginProtocol>
@end



@interface OKAuthProvider (Wrapper)

- (id)initWithClass:(Class)providerClass;
- (NSString*)serviceName;
- (BOOL)isUIVisible;
- (BOOL)isSessionOpen;
- (BOOL)start;
- (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler;
- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler;
- (void)logoutAndClear;
- (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)handleDidBecomeActive;
- (void)handleWillTerminate;

@end
