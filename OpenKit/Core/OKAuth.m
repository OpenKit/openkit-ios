//
//  OKAuth.m
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKAuth.h"
#import "OKAuthPlugin.h"
#import "OKMacros.h"
#import "OKError.h"


static NSMutableArray *__providers = nil;

@implementation OKAuthProvider

+ (OKAuthProvider*)providerByName:(NSString*)name
{
    for(OKAuthProvider *provider in __providers) {
        if([[provider serviceName] isEqualToString:name])
            return provider;
    }
    return nil;
}


+ (NSUInteger)indexForPriority:(NSInteger)priority
{
    NSUInteger index = 0;
    for(OKAuthProvider *p in __providers) {
        if(priority >= [p priority])
            return index;
        else
            ++index;
    }
    return index;
}


+ (void)addProvider:(OKAuthProvider*)provider
{
    if(!__providers)
        __providers = [[NSMutableArray alloc] init];
    
    if(![provider isKindOfClass:[OKAuthProvider class]]) {
        OKLogErr(@"OKAuthProvider: Invalid auth provider.");
        return;
    }

    OKAuthProvider *p = [OKAuthProvider providerByName:[provider serviceName]];
    if(p == nil) {
        // adding new one
        OKLogInfo(@"OKAuthProvider: Adding provider: %@", [provider serviceName]);
        NSUInteger index = [OKAuthProvider indexForPriority:[provider priority]];
        [__providers insertObject:provider atIndex:index];
    }
}


+ (void)removeProvider:(OKAuthProvider*)provider
{
    OKAuthProvider *p = [OKAuthProvider providerByName:[provider serviceName]];
    [__providers removeObject:p];
}


+ (NSArray*)getProviders
{
    return [__providers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *d) {
        return [(OKAuthProvider*)obj isUIVisible] == true;
    }]];
}


+ (NSArray*)getAllProviders
{
    return __providers;
}


+ (BOOL)start
{
    BOOL anyOpen = NO;
    for(OKAuthProvider *provider in __providers) {
        if([provider start]) {
            OKLogInfo(@"OKAuthProvider: Opened cached session in %@", [provider serviceName]);
            anyOpen = YES;
        }
    }
    if(!anyOpen)
        OKLogInfo(@"OKAuthProvider: No cached session was opened");
    
    return anyOpen;
}


+ (void)logoutAndClear
{
    for(OKAuthProvider *provider in __providers) {
        OKLogInfo(@"OKAuthProvider: Logging out %@", [provider serviceName]);
        [provider logoutAndClear];
    }
}


+ (BOOL)handleOpenURL:(NSURL *)url
{
    if(!url)
        return NO;
    
    for(OKAuthProvider *provider in __providers) {
        if([provider handleOpenURL:url])
            return YES;
    }
    return NO;
}


+ (void)handleDidBecomeActive
{
    [__providers makeObjectsPerformSelector:@selector(handleDidBecomeActive)];
}


+ (void)handleWillTerminate
{
    [__providers makeObjectsPerformSelector:@selector(handleWillTerminate)];
}

@end


#pragma mark -

@interface OKAuthRequest ()
{
    NSString *_data;
    NSString *_key;
    NSString *_url;
}
@end


@implementation OKAuthRequest

- (id)initWithProvider:(OKAuthProvider*)provider
                userID:(NSString*)userid
              userName:(NSString*)username
          userImageURL:(NSString*)imageUrl
                 token:(NSString*)token
{
    NSParameterAssert(provider);
    NSParameterAssert(userid);
    
    self = [super init];
    if (self) {
        _provider = provider;
        _userID = userid;
        _userName = username;
        _userImageUrl = imageUrl;
        _key = token;
        _data = nil;
        _url = nil;
    }
    return self;
}


- (id)initWithProvider:(OKAuthProvider*)provider
                userID:(NSString*)userid
              userName:(NSString*)username
          userImageURL:(NSString*)imageUrl
                   key:(NSString*)key
                  data:(NSString*)data
          publicKeyUrl:(NSString*)url;
{
    NSParameterAssert(userid);
    if(!provider)
        return nil;

    self = [super init];
    if (self) {
        _provider = provider;
        _userID = userid;
        _userName = username;
        _userImageUrl = imageUrl;
        _key = key;
        _data = data;
        _url = url;
    }
    return self;
}


- (NSDictionary*)JSONDictionary
{
    NSAssert([_provider serviceName], @"The service's name can not be nil.");

    return @{@"service": [_provider serviceName],
             @"user_name": OK_NO_NIL(_userName),
             @"user_id": OK_NO_NIL(_userID),
             @"user_image_url": OK_NO_NIL(_userImageUrl), 
             @"key": OK_NO_NIL(_key),
             @"data": OK_NO_NIL(_data),
             @"public_key_url": OK_NO_NIL(_url) };
}

@end
