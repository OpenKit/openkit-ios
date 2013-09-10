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
#import "OKMacros.h"

#define DEFAULT_ENDPOINT    @"stage.openkit.io"


@interface OKManager ()
{
    OKUser *_currentUser;
}

@end


@implementation OKManager

static NSString *OK_USER_KEY = @"OKUserInfo";

@synthesize hasShownFBLoginPrompt, leaderboardListTag;

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
        
        [self getSavedUserFromNSUserDefaults];
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
    [self removeCachedUserFromNSUserDefaults];
    //Log out and clear Facebook
    [FBSession.activeSession closeAndClearTokenInformation];
    
    [[OKScoreCache sharedCache] clearCache];
}

- (void)saveCurrentUser:(OKUser *)aCurrentUser
{
    self->_currentUser = aCurrentUser;
    [self removeCachedUserFromNSUserDefaults];
    [self saveCurrentUserToNSUserDefaults];
    [[OKScoreCache sharedCache] submitAllCachedScores];
}

-(void)getSavedUserFromNSUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *archivedUserDict = [defaults objectForKey:OK_USER_KEY];
    
    if(archivedUserDict != nil) {
        if(![archivedUserDict isKindOfClass:[NSData class]]) {
            OKLog(@"OKUser cache is busted, clearing cache");
            [self removeCachedUserFromNSUserDefaults];
        } else {
            NSDictionary *userDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:archivedUserDict];
            OKUser *cachedUser = [OKUserUtilities createOKUserWithJSONData:userDictionary];
            _currentUser = cachedUser;
            OKLog(@"Found  cached OKUser id: %@ from defaults", [cachedUser OKUserID]);
            
            if(_currentUser == nil) {
                OKLog(@"OKUser cache is busted, clearing cache");
                [self removeCachedUserFromNSUserDefaults];
            }
        }
    } else {
        OKLog(@"Did not find cached OKUser");
        [self getSavedUserFromKeychainAndMoveToNSUserDefaults];
    }
}

-(void)saveCurrentUserToNSUserDefaults
{
    NSDictionary *userDict = [OKUserUtilities getJSONRepresentationOfUser:[OKUser currentUser]];
    NSData *archivedUserDict = [NSKeyedArchiver archivedDataWithRootObject:userDict];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:archivedUserDict forKey:OK_USER_KEY];
    [defaults synchronize];
}

-(void)removeCachedUserFromNSUserDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:OK_USER_KEY];
    [defaults synchronize];
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

// This method is used to migrate the OKUser cache from keychain
// to NSUserDefaults
// It clears out any saved data in Keychain and moves the cached OKUserID
// to NSUserDefaults
//

- (void)getSavedUserFromKeychainAndMoveToNSUserDefaults
{
    NSDictionary *userDict;
    NSData *keychainData = [SimpleKeychain retrieve];
    if(keychainData != nil) {
        userDict = [[NSKeyedUnarchiver unarchiveObjectWithData:keychainData] copy];
        OKLog(@"Found  cached OKUser from keychain, moving to NSUserDefaults");
        OKUser *old_cached_User = [OKUserUtilities createOKUserWithJSONData:userDict];
        
        // Clear the old cache
        [SimpleKeychain clear];
        OKLog(@"Cleared old OKUser cache");
        
        // getSavedUserFromKeychainAndMoveToNSUserDefaults gets called during app launch
        // and saveCurrentUserToNSUserDefaults makes a  call to [NSUserDefaults synchronize] which
        // can cause a lock during app launch, so we need to perform it on a bg thread
        if(old_cached_User != nil) {
            _currentUser = old_cached_User;
            OKLog(@"Saving user to new cache in background");
            [self performSelectorInBackground:@selector(saveCurrentUserToNSUserDefaults) withObject:nil];
        }
    }
}

@end
