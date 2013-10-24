//
//  OKUser.m
//  OKClient
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKUser.h"
#import "OKManager.h"
#import "OKNetworker.h"
#import "OKAuth.h"
#import "OKMacros.h"
#import "OKHelper.h"
#import "OKError.h"


@implementation OKUser

- (id)initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        [self configWithDictionary:dict];
    }
    return self;
}


- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    NSParameterAssert(dict && [dict isKindOfClass:[NSDictionary class]]);

    _userID = [OKHelper getNSStringFrom:dict key:@"id"];
    _userNick = [OKHelper getNSStringFrom:dict key:@"name"];
    _userImageUrl = [OKHelper getNSStringFrom:dict key:@"image_url"];
    _services = [OKHelper getNSDictionaryFrom:dict key:@"services"];
    
    return (_userID && _userNick);
}


- (NSString*)userIDForService:(NSString*)service
{
    return self.services[service];
}


- (NSDictionary*)dictionary
{
    return @{@"id": _userID,
             @"nick": _userNick,
             @"image_url": _userImageUrl,
             @"services": _services };
}


- (void)setUserNick:(NSString*)userNick
{
    _userNick = userNick;
}


- (void)setUserImageUrl:(NSString*)userImageUrl
{
    _userImageUrl = userImageUrl;
}


- (NSArray*)resolveConnections
{
    NSMutableArray *results = [NSMutableArray array];
    OKLocalUser *user = [OKLocalUser currentUser];
    if(user) {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *friends = [user friendsForService:key];
            if(friends && [friends rangeOfString:[self userID]].location != NSNotFound)
                [results addObject:key];
        }];
    }
    
    return results;
}

#pragma mark -

+ (OKUser*)guestUser
{
    OKUser *guestUser = [[OKUser alloc] init];
    [guestUser setUserNick:@"Me"];
    return guestUser;
}


+ (OKUser*)createUserWithDictionary:(NSDictionary*)dict
{
    if(!dict)
        return nil;
    
    return [[OKUser alloc] initWithDictionary:dict];
}

@end


@implementation OKLocalUser

- (BOOL)isAccessAllowed
{
    // REVIEW THIS
    return self.userID != nil;
    //return (self.userID && self.accessToken && self.accessTokenSecret);
}

- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    _accessToken = [OKHelper getNSStringFrom:dict key:@"token"];
    _accessTokenSecret = [OKHelper getNSStringFrom:dict key:@"token_secret"];
    _dirty = [NSMutableDictionary dictionaryWithDictionary:dict[@"dirty"]];
    _friends = [NSMutableDictionary dictionaryWithDictionary:dict[@"friends"]];
    
    return ([super configWithDictionary:dict] && _accessToken && _accessTokenSecret);
}


- (void)setUserNick:(NSString*)userNick
{
    if(![self.userNick isEqualToString:userNick]) {
        [super setUserNick:userNick];
        [self changeValue:self.userNick forKey:@"nick"];
    }
}


- (void)setUserImageUrl:(NSString*)imageUrl
{
    if(![self.userImageUrl isEqualToString:imageUrl]) {
        [super setUserImageUrl:imageUrl];
        [self changeValue:self.userImageUrl forKey:@"image_url"];
    }
}


- (void)setFriendIDs:(NSArray*)friends forService:(NSString*)service
{
    if([self userIDForService:service] == nil) {
        OKLogErr(@"You can not add friends from %@ because you are not logged in.", service);
        return;
    }
    
    if(!_friends)
        _friends = [NSMutableDictionary dictionary];
    
    // Serialize array
    NSString *oldFriendsString = _friends[service];
    NSString *newFriendsString = [OKHelper serializeArray:friends withSorting:YES];
    
    if(![oldFriendsString isEqualToString:newFriendsString]) {
        _friends[service] = newFriendsString;
        
        NSString *key = [NSString stringWithFormat:@"friends_%@", service];
        [self changeValue:newFriendsString forKey:key];
    }
}


- (NSString*)friendsForService:(NSString*)service
{
    return _friends[service];
}


- (void)changeValue:(id)value forKey:(NSString*)key
{
    if(!_dirty)
        _dirty = [NSMutableDictionary dictionary];
    
    _dirty[key] = OK_NO_NIL(value);
}


- (void)syncWithCompletion:(void(^)(NSError *error))handler
{
    if(!_dirty || [_dirty count] == 0) {
        if(handler)
            handler(nil);
        return;
    }
    
    [OKNetworker postToPath:@"localuser/"
                 parameters:_dirty
                 completion:^(id responseObject, NSError *error)
     {
         if(!error) {
             [_dirty removeAllObjects];
         }
         if(handler)
            handler(error);
     }];
}


- (NSDictionary*)dictionary
{
    NSAssert(_accessToken, @"Access token is invalid.");
    NSAssert(_dirty, @"Access token is invalid.");

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionary]];
    dict[@"token"] = _accessToken;
    dict[@"token_secret"] = _accessTokenSecret;
    
    if(_dirty)
    dict[@"dirty"] = _dirty;
    
    if(_friends)
    dict[@"_friends"] = _friends;
    
    return dict;
}


#pragma mark -

+ (OKLocalUser*)currentUser
{
    return [[OKManager sharedManager] currentUser];
}


+ (OKLocalUser*)createUserWithDictionary:(NSDictionary*)dict
{
    if(!dict)
        return nil;
    
    return [[OKLocalUser alloc] initWithDictionary:dict];
}


+ (void)loginWithAuthRequests:(NSArray*)requests
                   completion:(void(^)(OKLocalUser *user, NSError *error))handler
{
    NSParameterAssert(handler);
    
    
    if(requests && [requests count] > 0) {
        
        NSMutableArray *params = [NSMutableArray arrayWithCapacity:[requests count]];
        for(OKAuthRequest *request in requests)
            [params addObject:[request JSONDictionary]];
        
        // REVIEW THIS
        NSDictionary *paramsDict = @{@"requests": params};
        [OKNetworker postToPath:@"/users"
                     parameters:paramsDict
                     completion:^(id responseObject, NSError *error)
         {
             OKLocalUser *newUser = nil;
             if(!error) {
                 OKLog(@"Successfully created user ID");
                 newUser = [OKLocalUser createUserWithDictionary:responseObject];
                 
             } else {
                 OKLog(@"Failed to create user with error: %@", error);
             }
             handler(newUser, error);
         }];
    }
}

@end
