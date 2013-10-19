//
//  OKPrivate.h
//  OKClient
//
//  Created by Manu Mtz-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKManager.h"
#import "OKLeaderboard.h"
#import "OKAuth.h"
#import "OKUser.h"

@interface OKManager (Private)

+ (NSString*)secretKey;

@end


@interface OKLeaderboard (Private)

- (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError* error))handler;
+ (void)loadFromCache;

@end


@interface OKAuthProvider (Private)

+ (BOOL)start;
+ (BOOL)handleOpenURL:(NSURL *)url;
+ (void)handleDidBecomeActive;
+ (void)handleWillTerminate;
+ (void)logoutAndClear;

@end


@interface OKLocalUser (Private)

+ (OKLocalUser*)createUserWithDictionary:(NSDictionary*)dict;
+ (void)loginWithAuthRequests:(NSArray*)requests completion:(void(^)(OKLocalUser *user, NSError *error))handler;

@end
