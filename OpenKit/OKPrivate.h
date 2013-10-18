//
//  OKPrivate.h
//  OKClient
//
//  Created by Manu Mtz-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLeaderboard.h"


@interface OKLeaderboard (Private)

- (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError* error))handler;
+ (void)loadFromCache;

@end


@interface OKAuthProvider (Private)

+ (NSArray*)getAuthProviders;
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
