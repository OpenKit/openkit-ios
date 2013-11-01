//
//  OKUser.h
//  OKClient
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OKUser : NSObject

@property(nonatomic, readonly) NSString *userID;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *imageUrl;
@property(nonatomic, readonly) NSDictionary *services;

- (NSString*)userIDForService:(NSString*)service;
- (NSDictionary*)dictionary;
- (NSArray*)resolveConnections;

+ (OKUser*)guestUser;
+ (OKUser*)createUserWithDictionary:(NSDictionary*)dict;

@end


@interface OKLocalUser : OKUser
{
    NSMutableDictionary *_dirty;
    NSMutableDictionary *_friends;
}

@property(nonatomic, readonly) NSString *accessToken;
@property(nonatomic, readonly) NSString *accessTokenSecret;

- (BOOL)isAccessAllowed;
- (void)setName:(NSString *)userNick;
- (void)setImageUrl:(NSString *)imageUrl;

- (void)syncWithCompletion:(void(^)(NSError *error))handler;
- (NSString*)friendsForService:(NSString*)service;
- (NSDictionary*)friends;
- (void)setFriendIDs:(NSArray*)friends forService:(NSString*)service;

+ (OKLocalUser*)currentUser;
+ (OKLocalUser*)createUserWithDictionary:(NSDictionary*)dict;

@end

