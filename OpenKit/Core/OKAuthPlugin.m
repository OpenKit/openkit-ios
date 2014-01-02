//
//  OKAuth.m
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKAuthPlugin.h"
#import "OKMacros.h"
#import "OKError.h"


@implementation OKAuthPluginBase

+ (OKAuthProvider*)sharedInstance
{
    return [OKAuthProvider providerByName:[self serviceName]];
}

+ (OKAuthProvider*)inject
{
    OKAuthProvider *provider = [self sharedInstance];
    if(!provider && [self shouldInject]) {

        provider = [[OKAuthProvider alloc] initWithClass:[self class]];
        [OKAuthProvider addProvider:provider];
    }
    return provider;
}

+ (BOOL)handleOpenURL:(NSURL *)url
{
    // Override this method if you need it
    return NO;
}

+ (void)handleDidBecomeActive
{
    // Override this method if you need it
}

+ (void)handleWillTerminate
{
    // Override this method if you need it
}

+ (BOOL)shouldInject
{
    return YES;
}

+ (BOOL)isUIVisible
{
    return NO;
}

+ (NSString*)serviceName
{
    NSAssert(NO, @"Override this method");
    return @"unknown";
}

+ (BOOL)isSessionOpen
{
    NSAssert(NO, @"Override this method");
    return NO;
}

+ (BOOL)start
{
    return [self openSessionWithViewController:nil completion:nil];
}

+ (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler
{
    NSAssert(NO, @"Override this method");
    return NO;
}

+ (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSAssert(NO, @"Override this method");
}

+ (void)logoutAndClear
{
    // Override this method if you need it
}

+ (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler
{
    OKLogInfo(@"OKAuthProvider: loadFriendsWithCompletion is not implemented in %@", [self serviceName]);
    handler(nil, nil);
}

@end


@implementation OKAuthProvider (Wrapper)

- (id)initWithClass:(Class)providerClass
{
    self = [super init];
    if (self) {
        self.pluginClass = providerClass;
    }
    return self;
}

- (NSString*)serviceName
{
    return [self.pluginClass serviceName];
}

- (BOOL)isUIVisible
{
    return [self.pluginClass isUIVisible];
}

- (BOOL)isSessionOpen
{
    return [self.pluginClass isSessionOpen];
}

- (BOOL)start
{
    return [self.pluginClass start];
}

- (BOOL)openSessionWithViewController:(UIViewController*)controller completion:(void(^)(BOOL login, NSError *error))handler
{
    return [self.pluginClass openSessionWithViewController:controller completion:handler];
}

- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    return [self.pluginClass getAuthRequestWithCompletion:handler];
}

- (void)logoutAndClear
{
    return [self.pluginClass logoutAndClear];
}

- (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler
{
    return [self.pluginClass loadFriendsWithCompletion:handler];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [self.pluginClass handleOpenURL:url];
}

- (void)handleDidBecomeActive
{
    return [self.pluginClass handleDidBecomeActive];
}

- (void)handleWillTerminate
{
    return [self.pluginClass handleWillTerminate];
}

@end
