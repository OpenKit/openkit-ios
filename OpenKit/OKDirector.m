//
//  OKDirector.m
//  OKDirector
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "OKDirector.h"
#import "AFNetworking.h"
#import "OKUser.h"
#import "OKUserUtilities.h"
#import "OKFacebookUtilities.h"
#import "OKTwitterUtilities.h"
#import "SimpleKeychain.h"
#import "OKDefines.h"

#define DEFAULT_ENDPOINT    @"stage.openkit.io"


@interface OpenKit ()
{
    OKUser *_currentUser;
}

@property (nonatomic, strong) NSString *OKAppID;
@property (nonatomic, strong) NSString *endpoint;

@end


@implementation OpenKit

+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static OpenKit *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OpenKit alloc] init];
    });
    return sharedInstance;
}


+ (void)initializeWithAppID:(NSString *)appID
{
    [OpenKit sharedInstance];
    [FBProfilePictureView class];
    [[OpenKit sharedInstance] setOKAppID:appID];
    [OKFacebookUtilities OpenCachedFBSessionWithoutLoginUI];
}

- (id)init
{
    self = [super init];
    if (self) {
        [self getSavedUserFromKeychain];
        _endpoint = DEFAULT_ENDPOINT;
    }
    return self;
}

- (OKUser*)currentUser
{
    return _currentUser;
}

+ (void)setApplicationID:(NSString *)appID;
{
    [[OpenKit sharedInstance] setOKAppID:appID];
}

+ (NSString*)getApplicationID
{
    return [[OpenKit sharedInstance] OKAppID];
}

+ (void)setEndpoint:(NSString *)endpoint;
{
    [[OpenKit sharedInstance] setEndpoint:endpoint];
}

+ (NSString*)getEndpoint
{
    return [[OpenKit sharedInstance] endpoint];
}


- (void)logoutCurrentUser
{
    NSLog(@"Logged out of openkit");
    _currentUser = nil;
    [self removeCachedUserFromKeychain];
    //Log out and clear Facebook
    [FBSession.activeSession closeAndClearTokenInformation];
}

- (void)saveCurrentUser:(OKUser *)aCurrentUser
{
    self->_currentUser = aCurrentUser;
    [self removeCachedUserFromKeychain];
    [self saveCurrentUserToKeychain];
}

- (void)saveCurrentUserToKeychain
{
    NSDictionary *userDict = [OKUserUtilities getJSONRepresentationOfUser:[OKUser currentUser]];
    [SimpleKeychain store:[NSKeyedArchiver archivedDataWithRootObject:userDict]];
}

- (void)getSavedUserFromKeychain
{
    NSDictionary *userDict;
    NSData *keychainData = [SimpleKeychain retrieve];
    if(keychainData != nil) {
        userDict = [[NSKeyedUnarchiver unarchiveObjectWithData:keychainData] copy];
        NSLog(@"Found  cached OKUser");
        OKUser *cachedUser = [OKUserUtilities createOKUserWithJSONData:userDict];
        _currentUser = cachedUser;
    }
    else {
        NSLog(@"Did not find cached OKUser");
    }
}

- (void)removeCachedUserFromKeychain
{
    [SimpleKeychain clear];
}

+ (BOOL)handleOpenURL:(NSURL*)url
{
    return [OKFacebookUtilities handleOpenURL:url];
}

+ (void)handleDidBecomeActive
{
    [OKFacebookUtilities handleDidBecomeActive];
}

+ (void)handleWillTerminate
{
    [OKFacebookUtilities handleWillTerminate];
}


@end
