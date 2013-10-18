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


- (void)configWithDictionary:(NSDictionary*)dict
{
    _userID = [OKHelper getNSNumberFrom:dict key:@"id"];
    _userNick = [OKHelper getNSStringFrom:dict key:@"name"];
    _services = [OKHelper getNSDictionaryFrom:dict key:@"services"];
}


- (NSString*)userIDForService:(NSString*)service
{
    return [self.services objectForKey:service];
}


- (NSDictionary*)JSONDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            _userID, @"id",
            _userNick, @"name", nil];
}


- (NSDictionary*)dictionary
{
    NSDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:5];
    [dict setValue:_userID forKey:@"id"];
    [dict setValue:_userNick forKey:@"nick"];
    [dict setValue:_services forKey:@"services"];
    
    return dict;
}


- (void)setUserNick:(NSString *)userNick
{
    _userNick = userNick;
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

- (void)configWithDictionary:(NSDictionary*)dict
{
    [super configWithDictionary:dict];
    
    _accessToken = [OKHelper getNSStringFrom:dict key:@"token"];
    _accessTokenSecret = [OKHelper getNSStringFrom:dict key:@"token_secret"];
    _dirty = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"dirty"]];
    _friends = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"friends"]];
}


- (void)setUserNick:(NSString *)userNick
{
    if(![self.userNick isEqualToString:userNick]) {
        [super setUserNick:userNick];
        [self changeValues:[NSDictionary dictionaryWithObject:self.userNick forKey:@"nick"]];
    }
}


- (void)setFriendIDs:(NSArray*)friends forService:(NSString*)service
{
    if([self userIDForService:service] == nil) {
        OKLogErr(@"You can not add \"%@\" friends because you are not logged in %@", service, service);
        return;
    }
    
    if(!_friends)
        _friends = [NSMutableDictionary dictionary];
    
    // Serialize array
    NSString *oldFriendsString = [_friends objectForKey:service];
    NSString *newFriendsString = [OKHelper serializeArray:friends withSorting:YES];
    
    if(![oldFriendsString isEqualToString:newFriendsString]) {
        [_friends setValue:newFriendsString forKey:service];
        NSString *key = [NSString stringWithFormat:@"friends_%@", service];
        [self changeValues:[NSDictionary dictionaryWithObject:newFriendsString forKey:key]];
    }
}


- (NSString*)friendsForService:(NSString*)service
{
    return [_friends objectForKey:service];
}


- (void)changeValues:(NSDictionary*)params
{
    if(!_dirty)
        _dirty = [NSMutableDictionary dictionary];
    
    [_dirty addEntriesFromDictionary:params];
}


- (void)syncWithCompletion:(void(^)(NSError *error))handler
{
    if([_dirty count] == 0)
        handler(nil);
    
    NSString *path = [NSString stringWithFormat:@"localuser/"];
    [OKNetworker postToPath:path
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
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionary]];
    [dict setValue:_accessToken forKey:@"token"];
    [dict setValue:_accessTokenSecret forKey:@"token_secret"];
    [dict setValue:_dirty forKey:@"dirty"];
    return dict;
}


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


+ (void)loginWithAuthRequests:(NSArray*)requests completion:(void(^)(OKLocalUser *user, NSError *error))handler
{
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:[requests count]];
    for(OKAuthRequest *request in requests)
        [params addObject:[request JSONDictionary]];
    
    // REVIEW THIS
    //NSDictionary *dict = [NSDictionary dictionaryWithObject:params forKey:@"requests"];
    NSDictionary *dict = [(OKAuthRequest*)[requests objectAtIndex:0] JSONDictionary];
    [OKNetworker postToPath:@"/users"
                 parameters:dict
                  encrypted:YES
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

@end
