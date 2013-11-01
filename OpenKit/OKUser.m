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

    _name = OK_CHECK(dict[@"name"], NSString);
    _imageUrl = OK_CHECK(dict[@"image_url"], NSString);
    _services = OK_CHECK(dict[@"services"], NSDictionary);

    return !!(_name);
}


- (NSString*)userIDForService:(NSString*)service
{
    return self.services[service];
}


- (NSDictionary*)dictionary
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
    OKLocalUser *user = [OKLocalUser currentUser];
    if(user) {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *friends = [user friendsForService:key];
            // REVIEW
            //if(friends && [friends rangeOfString:[self userID]].location != NSNotFound)
            //    [results addObject:key];
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
    // REVIEW THIS
    return self.accessToken && self.accessTokenSecret;
    //return (self.userID && self.accessToken && self.accessTokenSecret);
}

- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    if(![super configWithDictionary:dict])
        return NO;

    _accessToken = OK_CHECK(dict[@"access_token"], NSString);
    _accessToken = OK_CHECK(dict[@"access_secret"], NSString);
    _dirty = [NSMutableDictionary dictionaryWithDictionary:dict[@"dirty"]];
    _friends = [NSMutableDictionary dictionaryWithDictionary:dict[@"friends"]];
    
    return (_accessToken && _accessTokenSecret);
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
    
    [OKNetworker postToPath:@"/localuser"
                 parameters:_dirty
                 completion:^(id responseObject, NSError *error)
     {
         if(!error) {
             [self->_dirty removeAllObjects];
         }
         if(handler)
            handler(error);
     }];
}


- (NSDictionary*)dictionary
{
    NSAssert(_accessToken, @"Access token is invalid.");
    NSAssert(_dirty, @"Access token is invalid.");

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
        NSDictionary *paramsDict = @{@"requests": params};
        [OKNetworker postToPath:@"/users"
                     parameters:paramsDict
                     completion:^(id responseObject, NSError *error)
         {
             OKLocalUser *newUser = nil;
             if(!error) {
                 newUser = [OKLocalUser createUserWithDictionary:responseObject];
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
