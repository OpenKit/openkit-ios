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
        if(![self configWithDictionary:dict])
            return nil;
    }
    return self;
}


- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    if(![dict isKindOfClass:[NSDictionary class]])
        return NO;

    _name       = DYNAMIC_CAST(NSString, dict[@"name"]);
    _imageUrl   = DYNAMIC_CAST(NSString, dict[@"image_url"]);
    _services   = DYNAMIC_CAST(NSDictionary, dict[@"services"]);

    return (_name != nil);
}


- (NSString*)userIDForService:(NSString*)service
{
    return self.services[service];
}


- (NSDictionary*)archive
{
    NSAssert(_name, @"Name can not be nil");

    return @{@"name": _name,
             @"image_url": OK_NO_NIL(_imageUrl),
             @"services": OK_NO_NIL(_services) };
}


- (void)setName:(NSString*)userName
{
    _name = userName;
}


- (void)setImageUrl:(NSString*)userImageUrl
{
    _imageUrl = userImageUrl;
}


- (NSArray*)resolveConnections
{
    NSMutableArray *results = [NSMutableArray array];
    OKLocalUser *localUser = [OKLocalUser currentUser];
    if(localUser) {
        [[localUser friends] enumerateKeysAndObjectsUsingBlock:^(id service, id friends, BOOL *stop) {

            NSString *userId = [self userIDForService:service];
            if([friends rangeOfString:userId].location != NSNotFound)
                [results addObject:service];
        }];
    }
    
    return results;
}

#pragma mark -

+ (OKUser*)guestUser
{
    OKUser *guestUser = [[OKUser alloc] init];
    [guestUser setName:@"Me"];
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
    return _accessToken && _accessTokenSecret;
}

- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    if(![super configWithDictionary:dict])
        return NO;

    _accessToken = DYNAMIC_CAST(NSString, dict[@"access_token"]);
    _accessTokenSecret = DYNAMIC_CAST(NSString, dict[@"access_secret"]);
    _dirty = [NSMutableDictionary dictionaryWithDictionary:DYNAMIC_CAST(NSDictionary, dict[@"dirty"])];
    _friends = [NSMutableDictionary dictionaryWithDictionary:DYNAMIC_CAST(NSDictionary, dict[@"friends"])];
    
    return [self isAccessAllowed];
}


- (void)setName:(NSString*)userName
{
    if(![self.name isEqualToString:userName]) {
        [super setName:userName];
        [self changeValue:userName forKey:@"name"];
    }
}


- (void)setImageUrl:(NSString*)imageUrl
{
    if(![self.imageUrl isEqualToString:imageUrl]) {
        [super setImageUrl:imageUrl];
        [self changeValue:imageUrl forKey:@"image_url"];
    }
}


- (void)setFriendIDs:(NSArray*)friends forService:(NSString*)service
{
    if([self userIDForService:service] == nil) {
        OKLogErr(@"OKUser: You can not add friends from %@ because you are not logged in.", service);
        return;
    }

    [self friends];

    // Serialize array
    NSString *oldFriendsString = _friends[service];
    NSString *newFriendsString = [OKHelper serializeArray:friends withSorting:YES];
    
    if(![oldFriendsString isEqualToString:newFriendsString]) {
        _friends[service] = newFriendsString;
        
        NSString *key = [NSString stringWithFormat:@"friends_%@", service];
        [self changeValue:newFriendsString forKey:key];
    }
}


- (NSDictionary*)friends
{
    if(!_friends)
        _friends = [NSMutableDictionary dictionary];

    return _friends;
}


- (NSString*)friendsForService:(NSString*)service
{
    return [_friends objectForKey:service];
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
    
    [OKNetworker postToPath:@"/localuser"
                 parameters:_dirty
                 completion:^(OKResponse *response)
     {
         NSError *error = [response error];
         if(!error) {
             [self->_dirty removeAllObjects];
         }
         if(handler)
            handler(error);
     }];
}


- (NSDictionary*)archive
{
    NSAssert(_accessToken, @"Access token is invalid.");
    NSAssert(_accessTokenSecret, @"Access token is invalid.");

    return @{@"access_token": _accessToken,
             @"access_secret": _accessTokenSecret,
             @"dirty": OK_NO_NIL(_dirty),
             @"friends": OK_NO_NIL(_friends) };
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
        [OKNetworker postToPath:@"/users"
                     parameters:@{@"requests": params}
                     completion:^(OKResponse *response)
         {
             NSError *error = [response error];
             OKLocalUser *newUser = nil;
             if(!error) {
                 newUser = [OKLocalUser createUserWithDictionary:[response jsonObject]];
                 if(!newUser) // REVIEW
                     error = [OKError unknownError];
             }

             if(!error)
                 OKLogInfo(@"OKLocalUser: Successfully created user.");
             else
                 OKLogErr(@"OKLocalUser: Failed to create user.");

             handler(newUser, error);
         }];
    }else{
        // REVIEW
        handler(nil, [OKError unknownError]);
    }
}

@end
