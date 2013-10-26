//
//  OKAuth.h
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OKAuthRequest;
@class OKAuthProfile;


@interface OKAuthProvider : NSObject

@property(nonatomic, readwrite) NSInteger priority;
@property(nonatomic, readonly) NSString *serviceName;


- (id)initWithName:(NSString*)name;
+ (void)addProvider:(OKAuthProvider*)provider;
+ (OKAuthProvider*)providerByName:(NSString*)name;
+ (NSArray*)getProviders;


// REQUIRED TO OVERRIDE
+ (OKAuthProvider*)sharedInstance;

//! Returns if the authentication services are available.
//! e.g. GameCenter can't provide authentication until iOS7.0
- (BOOL)isUIVisible;

//! Returns if the session is already open.
//! This method should NOT try to open it.
- (BOOL)isSessionOpen;

//! Do not call this directly.  This method is called internally by OKManager.
//! Your implementation of -start must:
//! - Try to open the session without making the user login, ie. doesn't display UI.
//! - Start handling any related event from the service like state changes (logged in, logged out) and errors.
//! - Post a notification (OKAuthProviderUpdatedNotification) each state change.
//! - Return YES if the session was opened synchronously.
- (BOOL)start;

//! This method can be called directly from the developer's code.
//! If the controller is valid and the session is not open yet, this method should display the UI needed for login.
//! Return YES if the session was opened synchronously.
- (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler;


//! Called internally to get an valid OK Auth Request,
//! we need this to login into openkit and get an openkit user ID.
- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler;

//! This method should:
//! - Try to close the session.
//! - Try remove any cached data.
- (void)logoutAndClear;


// optional
- (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler;

- (BOOL)handleOpenURL:(NSURL *)url;
- (void)handleDidBecomeActive;
- (void)handleWillTerminate;

@end


@interface OKAuthRequest : NSObject

@property(nonatomic, readonly) OKAuthProvider *provider;
@property(nonatomic, readonly) NSString *userID;
@property(nonatomic, readonly) NSString *userName;
@property(nonatomic, readonly) NSString *userImageUrl;

- (id)initWithProvider:(OKAuthProvider*)provider
                userID:(NSString*)userid
              userName:(NSString*)username
          userImageURL:(NSString*)imageUrl
                 token:(NSString*)token;


- (id)initWithProvider:(OKAuthProvider*)provider
                userID:(NSString*)userid
              userName:(NSString*)username
          userImageURL:(NSString*)imageUrl
                   key:(NSString*)key
                  data:(NSString*)data
          publicKeyUrl:(NSString*)url;


- (NSDictionary*)JSONDictionary;

@end

