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
#import "OKLeaderboardsViewController.h"
#import "OKScoreCache.h"

#define DEFAULT_ENDPOINT    @"stage.openkit.io"


@interface OKManager ()
{
    OKUser *_currentUser;
}

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

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(willShowDashboard:) name:OKLeaderboardsViewWillAppear object:nil];
        [nc addObserver:self selector:@selector(didShowDashboard:)  name:OKLeaderboardsViewDidAppear object:nil];
        [nc addObserver:self selector:@selector(willHideDashboard:) name:OKLeaderboardsViewWillDisappear object:nil];
        [nc addObserver:self selector:@selector(didHideDashboard:)  name:OKLeaderboardsViewDidDisappear object:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Do not call super here.  Using arc.
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

+ (void)setSecretKey:(NSString *)secretKey
{
    [[OKManager sharedManager] setSecretKey:secretKey];
}

+ (NSString *)secretKey
{
    return [[OKManager sharedManager] secretKey];
}

- (void)logoutCurrentUser
{
    NSLog(@"Logged out of openkit");
    _currentUser = nil;
    [self removeCachedUserFromKeychain];
    //Log out and clear Facebook
    [FBSession.activeSession closeAndClearTokenInformation];
    
    [[OKScoreCache sharedCache] clearCache];
}

- (void)saveCurrentUser:(OKUser *)aCurrentUser
{
    self->_currentUser = aCurrentUser;
    [self removeCachedUserFromKeychain];
    [self saveCurrentUserToKeychain];
    [[OKScoreCache sharedCache] submitAllCachedScores];
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
    [[OKScoreCache sharedCache] submitAllCachedScores];
}

+ (void)handleWillTerminate
{
    [OKFacebookUtilities handleWillTerminate];
}

#pragma mark - Dashboard Display State Callbacks
- (void)willShowDashboard:(NSNotification *)note
{
    if(_delegate && [_delegate respondsToSelector:@selector(openkitManagerWillShowDashboard:)]) {
        [_delegate openkitManagerWillShowDashboard:self];
    }
}

- (void)didShowDashboard:(NSNotification *)note
{
    if(_delegate && [_delegate respondsToSelector:@selector(openkitManagerDidShowDashboard:)]) {
        [_delegate openkitManagerDidShowDashboard:self];
    }
}

- (void)willHideDashboard:(NSNotification *)note
{
    if(_delegate && [_delegate respondsToSelector:@selector(openkitManagerWillHideDashboard:)]) {
        [_delegate openkitManagerWillHideDashboard:self];
    }
}

- (void)didHideDashboard:(NSNotification *)note
{
    if(_delegate && [_delegate respondsToSelector:@selector(openkitManagerDidHideDashboard:)]) {
        [_delegate openkitManagerDidHideDashboard:self];
    }
}

@end
