//
//  OKManager.m
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "OKManager.h"
#import "OKUser.h"
#import "OKUserUtilities.h"
#import "OKFacebookUtilities.h"
#import "OKTwitterUtilities.h"
#import "SimpleKeychain.h"
#import "OKDefines.h"
#import "OKUserProfileImageView.h"

#define DEFAULT_ENDPOINT    @"stage.openkit.io"


@interface OKManager ()
{
    OKUser *_currentUser;
}

@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *endpoint;

@end


@implementation OKManager

+ (id)sharedManager
{
    static dispatch_once_t pred;
    static OKManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKManager alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self getSavedUserFromKeychain];
        _endpoint = DEFAULT_ENDPOINT;

        // These two lines below are required for the linker to work properly such that these classes are available in XIB files
        // This tripped me up for way to long.
        [FBProfilePictureView class];
        [OKUserProfileImageView class];
        
        [OKFacebookUtilities OpenCachedFBSessionWithoutLoginUI];
    }
    return self;
}

- (OKUser*)currentUser
{
    return _currentUser;
}

+ (void)setAppKey:(NSString *)appKey
{
    [[OKManager sharedManager] setAppKey:appKey];
}

+ (NSString *)appKey
{
    return [[OKManager sharedManager] appKey];
}

+ (void)setEndpoint:(NSString *)endpoint;
{
    [[OKManager sharedManager] setEndpoint:endpoint];
}

+ (NSString *)endpoint
{
    return [[OKManager sharedManager] endpoint];
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
