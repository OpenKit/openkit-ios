//
//  OKManager.m
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKManager.h"
#import "OKUser.h"
#import "OKFacebookUtilities.h"
#import "OKDefines.h"
#import "OKDBScore.h"
#import "OKDBConnection.h"
#import "OKDBSession.h"
#import "OKMacros.h"
#import "OKAuth.h"
#import "OKPrivate.h"
#import "OKCrypto.h"
#import "OKNetworker.h"
#import "OKFileUtil.h"
#import "OKNotifications.h"
#import "OKUtils.h"

#define OK_LOCAL_SESSION @"openkit.session"
#define OK_DEFAULT_ENDPOINT @"http://api.openkit.io"
#define OK_OPENKIT_SDK_VERSION = @"2.0";



@interface OKManager ()
{
    OKLocalUser *_currentUser;
}

@property(nonatomic, strong) NSString *appKey;
@property(nonatomic, strong) NSString *secretKey;
@property(nonatomic, strong) NSString *endpoint;

@end


@implementation OKManager

+ (BOOL)handleOpenURL:(NSURL*)url
{
    return [OKAuthProvider handleOpenURL:url];
}


+ (NSString*)appKey
{
    return [[OKManager sharedManager] appKey];
}


+ (NSString*)endpoint
{
    return [[OKManager sharedManager] endpoint];
}


+ (NSString*)secretKey
{
    return [[OKManager sharedManager] secretKey];
}


+ (void)configureWithAppKey:(NSString *)appKey
                  secretKey:(NSString *)secretKey
                   endpoint:(NSString *)endpoint
{
    NSParameterAssert(appKey);
    NSParameterAssert(secretKey);
    
    OKManager *manager = [OKManager sharedManager];
    [manager setAppKey:appKey];
    [manager setSecretKey:secretKey];
    [manager setEndpoint:(endpoint) ? endpoint : OK_DEFAULT_ENDPOINT];
    
    OKLog(@"OpenKit configured with endpoint: %@", [[OKManager sharedManager] endpoint]);
    
    [manager setup];
}


+ (void)configureWithAppKey:(NSString*)appKey secretKey:(NSString*)secretKey
{
    [OKManager configureWithAppKey:appKey secretKey:secretKey endpoint:nil];
}


+ (id)sharedManager
{
    static dispatch_once_t pred;
    static OKManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKManager alloc] init];
    });
    return sharedInstance;
}


#pragma mark -

- (id)init
{
    self = [super init];
    if (self) {
        _endpoint = OK_DEFAULT_ENDPOINT;
        _initialized = NO;
    }
    return self;
}

- (void)setup
{
    // Init crytor
    _cryptor = [[OKCrypto alloc] initWithMasterKey:_secretKey];
    
    // Preload leaderboards from cache
    [OKLeaderboard loadFromCache];

    [self startSession];
    [self startLogin];
}


#pragma mark - Login management

- (void)startLogin
{
    OKLogInfo(@"Initializing Openkit...");
    
    // Starting authorization providers (opening sessions from cache...)
    [OKAuthProvider start];

    // Try to open OK session from cache
    OKLocalUser *user = [self getCachedUser];
    if(user) {
        OKLogInfo(@"Opened Openkit session from cache.");
        [self setCurrentUser:user];
        [self endLogin];
        return;
    }
    
    
    // At this point we are not logged in Openkit, we try to get access using cached sessions.
    NSArray *providers = [OKAuthProvider getAuthProviders];
    if(!providers || [providers count] == 0) {
        OKLogErr(@"You should add at less one authorization provider.");
        [self endLogin];
        return;
    }
    
    
    // We wait a time to make app start faster and wait until services are initialized.
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        
        NSLock* lock = [NSLock new];
        NSMutableArray *authRequests = [NSMutableArray arrayWithCapacity:[providers count]];
        OKMutableInt *count = [[OKMutableInt alloc] initWithValue:[providers count]];
        
        for(OKAuthProvider *provider in providers) {
            [provider getAuthRequestWithCompletion:^(OKAuthRequest *request, NSError *error) {
                
                [lock lock];
                if(request)
                    [authRequests addObject:request];
                
                [lock unlock];
                
                if((--count.value) == 0)
                    [self performAuthRequest:authRequests];
            }];
        }
    });
}


- (void)performAuthRequest:(NSMutableArray*)authRequests
{
    if(!authRequests || [authRequests count] == 0) {
        [self endLogin];
        return;
    }

    [OKLocalUser loginWithAuthRequests:authRequests
                            completion:^(OKLocalUser *user, NSError *error) {
        if(user)
            [self setCurrentUser:user];
        
        [self endLogin];
    }];
}


- (void)endLogin
{
    NSAssert([NSThread mainThread], @"Callback must be in main thread");
    NSAssert(_initialized == NO, @"Bad state, this method just can be called once.");
    
    OKLogInfo(@"End initialization");
    _initialized = YES;
    
    
    // At this point we can receive notifications and the user can user OKManager normally.
    // Add any observer here:
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // REVIEW
//    [nc addObserver:self selector:@selector(willShowDashboard:) name:OKLeaderboardsViewWillAppear object:nil];
//    [nc addObserver:self selector:@selector(didShowDashboard:)  name:OKLeaderboardsViewDidAppear object:nil];
//    [nc addObserver:self selector:@selector(willHideDashboard:) name:OKLeaderboardsViewWillDisappear object:nil];
//    [nc addObserver:self selector:@selector(didHideDashboard:)  name:OKLeaderboardsViewDidDisappear object:nil];
    [nc addObserver:self selector:@selector(providerUpdated:) name:OKAuthProviderUpdatedNotification object:nil];
    [nc addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(enteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(becameAction) name:UIApplicationDidBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(willTerminate) name:UIApplicationWillTerminateNotification object:nil];

    
    if(_delegate && [_delegate respondsToSelector:@selector(openkitDidLaunch:)])
        [_delegate openkitDidLaunch:self];
    
    if(![self currentUser])
        OKLogInfo(@"Not login in openkit.");
    else
        [self updatedStatus];
}


- (void)loginWithProvider:(OKAuthProvider*)provider
               completion:(void(^)(OKLocalUser *user, NSError *error))handler
{
    if(!provider)
        return;
    
    OKLogInfo(@"Trying to login with %@", [provider serviceName]);
    [provider getAuthRequestWithCompletion:^(OKAuthRequest *request, NSError *error) {
        [OKLocalUser loginWithAuthRequests:@[request] completion:handler];
    }];
}


- (void)updatedStatus
{
    OKLocalUser *user = [self currentUser];
    
    if(user) {
        OKLogInfo(@"Logged in successfully: User id: %@", [user userID]);
        
        // once we are logged in, we perform some tasks
        // start local session (analytics)
        [OKSession resolveUnsubmittedSession];
        
        // update friends
        [self updateFriendsLazily:YES withCompletion:nil];
        
        // update local user data
        [user syncWithCompletion:nil];
        
        // resolve pending scores
        [OKScore resolveUnsubmittedScores];
        
        // get list of leaderboards as soon as possible
        [OKLeaderboard getLeaderboardsWithCompletion:nil];
        
    }else{
        // logout
        
    }
    
    if(_delegate && [_delegate respondsToSelector:@selector(openkitDidChangeStatus:)])
        [_delegate openkitDidChangeStatus:self];
}


#pragma mark - User management and status

- (OKLocalUser*)currentUser
{
    @synchronized(self) {
        return _currentUser;
    }
}


- (void)setCurrentUser:(OKLocalUser*)aCurrentUser
{
    if([_currentUser userID] != [aCurrentUser userID]) {
        _currentUser = aCurrentUser;
        [self updateCachedUser];
        if([self initialized])
            [self updatedStatus];
    }
}


- (void)updateFriendsLazily:(BOOL)lazy withCompletion:(void(^)(NSError* error))handler
{
    OKLocalUser *user = [self currentUser];
    if(!user) {
        OKLogErr(@"We can't upload friends because we are not logged in.");
        return;
    }
    
    NSArray *providers = [OKAuthProvider getAuthProviders];
    for(OKAuthProvider *provider in providers) {
        if([provider isSessionOpen]) {
            if(!([user friendsForService:[provider serviceName]] && lazy)) {
                [provider loadFriendsWithCompletion:^(NSArray *friends, NSError *error) {
                    if(!error && friends) {
                        [user setFriendIDs:friends forService:[provider serviceName]];
                    }
                }];
            }
        }
    }
    if(handler)
    handler(nil);
}


- (OKLocalUser*)getCachedUser
{
    NSString *path = [OKFileUtil localOnlyCachePath:OK_LOCAL_SESSION];
    NSDictionary *dict = [OKFileUtil readSecureFile:path];
    return [OKLocalUser createUserWithDictionary:dict];
}


- (BOOL)updateCachedUser
{
    OKLocalUser *user = [self currentUser];
    if([user isAccessAllowed]) {
        OKLogInfo(@"Updating local user in cache.");
        NSString *path = [OKFileUtil localOnlyCachePath:OK_LOCAL_SESSION];
        [OKFileUtil writeOnFileSecurely:[user dictionary] path:path];
    }
    return NO;
}


- (void)removeCachedUser
{
    NSString *path = [OKFileUtil localOnlyCachePath:OK_LOCAL_SESSION];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}


- (void)logoutCurrentUser
{
    OKLogInfo(@"Logging out of openkit");
    [self removeCachedUser];
    [self setCurrentUser:nil];
    
    //[OKAuthProvider logoutAndClear];
    [OKScore clearSubmittedScore];
}


- (void)registerToken:(NSData *)deviceToken
{
    OKLog(@"OKManager registerToken, data: %@", deviceToken);
    
    const unsigned *tokenBytes = [deviceToken bytes];
    
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    OKLogInfo(@"cache queue is %s", dispatch_queue_get_label(OK_CACHE_QUEUE()));
    dispatch_async(OK_CACHE_QUEUE(), ^{
        [OKSession registerPush:hexToken];
    });
}


#pragma mark - Notifications

- (void)providerUpdated:(NSNotification*)not
{
    if(![self initialized])
        OKLogErr(@"The system is not initialized yet.");
    
    OKAuthProvider *provider = [not object];
    
    // Validate provider
    BOOL isInjected = [[OKAuthProvider getAuthProviders] containsObject:provider];
    BOOL alreadyLogged = [[self currentUser] userIDForService:[provider serviceName]] != nil;
    
    // If the provider is valid and we are not already logged in, we try to log in.
    if([provider isSessionOpen] && isInjected && !alreadyLogged) {
        
        [self loginWithProvider:provider completion:^(OKLocalUser *user, NSError *error) {
            if(user) {
                [self updateCachedUser];
                [self setCurrentUser:user];
                
                
                // update friends
                [provider loadFriendsWithCompletion:^(NSArray *friends, NSError *error) {
                    if(!error && friends) {
                        [user setFriendIDs:friends forService:[provider serviceName]];
                    }
                }];
            }
        }];
    }
}


- (void)willEnterForeground
{
    
}


- (void)enteredBackground
{
    // Save changes in disk.
    [self updateCachedUser];
}


- (void)becameAction
{
    [OKAuthProvider handleDidBecomeActive];
    [[OKManager sharedManager] submitCachedScoresAfterDelay];
}


- (void)willTerminate
{
    [OKAuthProvider handleWillTerminate];

}

/* REVIEW
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
 */


#pragma mark - Private

// REVIEW
- (void)startSession
{
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (100.0f * NSEC_PER_MSEC));
    dispatch_after(delay, OK_CACHE_QUEUE(), ^{
        [OKSession activate];
    });
    
    [self submitCachedScoresAfterDelay];
}


- (void)submitCachedScoresAfterDelay
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [OKScore resolveUnsubmittedScores];
    });
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Do not call super here.  Using arc.
}

@end
