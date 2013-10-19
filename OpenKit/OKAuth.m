//
//  OKAuth.m
//  OpenKit
//
//  Created by Manu Mtz-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKAuth.h"
#import "OKMacros.h"
#import "OKError.h"


NSMutableArray *__providers = nil;

@implementation OKAuthProvider

+ (OKAuthProvider*)providerByName:(NSString*)name
{
    for(OKAuthProvider *provider in __providers) {
        if([[provider serviceName] isEqualToString:name])
            return provider;
    }
    return nil;
}


+ (int)indexForPriority:(int)priority
{
    int index = 0;
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
        OKLogErr(@"Invalid auth provider.");
        return;
    }
    
    if(![provider isAuthenticationAvailable]) {
        OKLogErr(@"Provider is not available.");
        return;
    }

    OKAuthProvider *p = [OKAuthProvider providerByName:[provider serviceName]];
    if(p == nil) {
        // adding new one
        int index = [OKAuthProvider indexForPriority:[provider priority]];
        [__providers insertObject:provider atIndex:index];
    }
}


+ (void)removeProvider:(OKAuthProvider*)provider
{
    OKAuthProvider *p = [OKAuthProvider providerByName:[provider serviceName]];
    [__providers removeObject:p];
}


+ (NSArray*)getAuthProviders
{
    return __providers;
}


+ (BOOL)start
{
    BOOL anyOpen = NO;
    for(OKAuthProvider *provider in __providers) {
        if([provider start]) {
            OKLogInfo(@"Opened cached session in %@", [provider serviceName]);
            anyOpen = YES;
        }
    }
    if(!anyOpen)
        OKLogInfo(@"No cached session was opened");
    
    return anyOpen;
}


+ (void)logoutAndClear
{
    for(OKAuthProvider *provider in __providers) {
        OKLogInfo(@"Logging out %@", [provider serviceName]);
        [provider logoutAndClear];
    }
}


+ (BOOL)handleOpenURL:(NSURL *)url
{
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


#pragma mark - Instance methods

- (id)initWithName:(NSString*)name
{
    self = [super init];
    if (self) {
        _serviceName = name;
    }
    return self;
}


#pragma mark - Methods to override


+ (OKAuthProvider*)inject
{
    NSAssert(NO, @"Override this method");
    return nil;
}

- (id)init
{
    NSAssert(NO, @"OKAuthProvider must be initialized with -initWithName:");
    return nil;
}

- (BOOL)isAuthenticationAvailable
{
    NSAssert(NO, @"Override this method");
    return NO;
}

- (BOOL)isSessionOpen
{
    NSAssert(NO, @"Override this method");
    return NO;
}

- (BOOL)start
{
    NSAssert(NO, @"Override this method");
    return NO;
}

- (BOOL)openSessionWithViewController:(UIViewController*)controller completion:(void(^)(NSError *error))handler
{
    NSAssert(NO, @"Override this method");
    return NO;
}

- (void)openSessionWithCompletion:(void(^)(NSError *error))handler
{
    NSAssert(NO, @"Override this method");
}

- (void)getProfileWithCompletion:(void(^)(OKAuthProfile *request, NSError *error))handler
{
    NSAssert(NO, @"Override this method");
}

- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSAssert(NO, @"Override this method");
}

- (void)logoutAndClear
{
    NSAssert(NO, @"Override this method");
}

- (void)loadUserImageForUserID:(NSString*)userid completion:(void(^)(UIImage *image, NSError *error))handler
{
    OKLogInfo(@"loadUserImageForUserID is not implemented in %@", [self serviceName]);
    handler(nil, nil);
}

- (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler
{
    OKLogInfo(@"loadFriendsWithCompletion is not implemented in %@", [self serviceName]);
    handler(nil, nil);
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    // Override this method if you need it
    return NO;
}

- (void)handleDidBecomeActive
{
    // Override this method if you need it
}

- (void)handleWillTerminate
{
    // Override this method if you need it
}

@end


#pragma mark -

@implementation OKAuthProfile

- (id)initWithProvider:(OKAuthProvider*)provider userID:(NSString*)userid name:(NSString*)name
{
    self = [super init];
    if (self) {
        _provider = provider;
        _userID = userid;
        _userName = name;
    }
    return self;
}


- (void)getFriendsWithCompletion:(void(^)(NSArray *ids, NSError *error))handler;
{
    if(_friends) {
        handler(_friends, nil);
        
    }else{
        [_provider loadFriendsWithCompletion:^(NSArray *friends, NSError *error) {
            if(friends)
                _friends = friends;
            
            handler(_friends, error);
        }];
    }
}

@end


@implementation OKAuthRequest

- (id)initWithProvider:(OKAuthProvider*)provider userID:(NSString*)userID token:(NSString*)token
{
    self = [super init];
    if (self) {
        _provider = provider;
        _data = userID;
        _key = token;
    }
    return self;
}


- (id)initWithProvider:(OKAuthProvider*)provider publicKeyUrl:(NSString*)url signature:(NSData*)signature data:(NSData*)data;
{
    self = [super init];
    if (self) {
        _provider = provider;
        _data = data;
        _key = signature;
        _url = url;
    }
    return self;
}


- (NSDictionary*)JSONDictionary
{
    return @{
             @"service": [_provider serviceName],
             @"data": _data,
             @"key": _key,
             @"public_key_url": _url };
}

@end
