//
//  OKSessionDb.h
//  OpenKit
//
//  Created by Louis Zell on 8/22/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
//
#import <Foundation/Foundation.h>
#import "OKDBConnection.h"


@interface OKSession : OKDBRow

@property(nonatomic, copy) NSString *token;
@property(nonatomic, copy) NSString *fbId;
@property(nonatomic, copy) NSString *googleId;
@property(nonatomic, copy) NSString *customId;
@property(nonatomic, copy) NSString *pushToken;
// Temporary.
@property(nonatomic, copy) NSString *okId;


- (id)initWithDictionary:(NSDictionary*)dict;
- (BOOL)configWithDictionary:(NSDictionary*)dict;
- (NSDictionary*)JSONDictionary;
- (OKSession*)getNewSession;

+ (OKSession*)currentSession;
+ (void)activate;
+ (void)resolveUnsubmittedSession;
+ (void)registerPush:(NSString *)pushToken;
+ (void)loginFB:(NSString *)aFacebookId;
+ (void)logoutFB;
+ (void)loginGoogle:(NSString *)aGoogleId;
+ (void)logoutGoogle;
+ (void)loginCustom:(NSString *)aCustomId;
+ (void)logoutCustom;

// Temporary.
+ (void)loginOpenKit:(NSString *)anOpenKitId;
+ (void)logoutOpenKit;

@end

