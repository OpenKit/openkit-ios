//
//  OKManager.m
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#include <sys/sysctl.h>
#include <objc/message.h>
#import "OKManager.h"
#import "OKUser.h"
#import "OKMacros.h"
#import "OKAuth.h"
#import "OKDefines.h"
#import "OKPrivate.h"
#import "OKFileUtil.h"
#import "OKNotifications.h"
#import "OKScore.h"
#import "OKUtils.h"


#define OK_LOCAL_USER @"user.ok"

@implementation OKClient

- (id)init
{
    self = [super init];
    if (self) {
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *model = malloc(size);
        sysctlbyname("hw.machine", model, &size, NULL, 0);
        _deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
        free(model);
    }
    return self;
}

- (BOOL)isValid
{
    BOOL validKey = [_consumerKey length] > 5;
    BOOL validSecret = [_consumerKey length] > 10;
    BOOL validHost = [_host length] > 10;

    return (validKey && validSecret && validHost);
}

@end


@interface OKManager ()
{
    OKLocalUser *_currentUser;
}
@end


static OKManager *__sharedInstance = nil;

@implementation OKManager

+ (BOOL)handleOpenURL:(NSURL*)url
{
    return [OKAuthProvider handleOpenURL:url];
}


+ (void)injectDefaultPlugins
{
    // Inject facebook's plugin.
    Class fbPlugin = NSClassFromString(@"OKFacebookPlugin");
    if(fbPlugin)
        objc_msgSend(fbPlugin, @selector(sharedInstance));

    Class gcPlugin = NSClassFromString(@"OKFacebookPlugin");
    gcPlugin = NSClassFromString(@"OKGameCenterPlugin");
    if(gcPlugin)
        objc_msgSend(gcPlugin, @selector(sharedInstance));

}


+ (void)configureWithAppKey:(NSString *)appKey
                  secretKey:(NSString *)secretKey
                       host:(NSString *)host
{
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{

        [self injectDefaultPlugins];

        OKClient *client = [[OKClient alloc] init];
        client.consumerKey = appKey;
        client.consumerSecret = secretKey;
        client.host = (host) ? host : OK_DEFAULT_SERVER_HOST;

        __sharedInstance = [[OKManager alloc] initWithClient:client];
        OKLogInfo(@"OpenKit configured with host: %@", client.host);
    });

    [__sharedInstance setup];
}


+ (void)configureWithAppKey:(NSString*)appKey secretKey:(NSString*)secretKey
{
    [OKManager configureWithAppKey:appKey secretKey:secretKey host:nil];
}


+ (id)sharedManager
{
    if(!__sharedInstance)
        OKLogErr(@"OKManager: Manager was not configured.");

    return __sharedInstance;
}


#pragma mark -

- (id)initWithClient:(OKClient*)client
{
    NSAssert([client isValid], @"Invalid client credentials.");
    self = [super init];
    if (self) {
        _initialized = NO;
        _client = client;
        _leaderboardListTag = OK_DEFAULT_LEADERBOARD_LIST_TAG;

        // We generate a master key (consumerKey+vendorUUID+bundleID)
        NSString *masterKey = [NSString stringWithFormat:@"%@%@%@",
                               [client consumerSecret],
                               [OKUtils vendorUUID],
                               [OKUtils bundleID]];
        _cryptor = [[OKCrypto alloc] initWithMasterKey:masterKey];
    }
    return self;
}


- (void)setup
{
    if(_initialized) {
        NSAssert(NO, @"Setup can no be called once the system is already initialized.");
        return;
    }

    // REVIEW
    //[OKLeaderboard loadFromCache];
    [self startLogin];
}


#pragma mark - Login management

- (void)startLogin
{
    OKLogInfo(@"OKManager: Initializing Openkit.");
    
    // Starting authorization providers (opening sessions from cache...)
    [OKAuthProvider start];

    // Try to open OK session from cache
    OKLocalUser *user = [self getCachedUser];
    if(user) {
        OKLogInfo(@"OKManager: Opened Openkit session from cache.");
        [self setCurrentUser:user];
        [self endLogin];
        return;
    }
    
    
    // At this point we are not logged in Openkit, we try to get access using cached sessions.
    NSArray *providers = [OKAuthProvider getAllProviders];
    if(!providers || [providers count] == 0) {
        OKLogErr(@"OKManager: You should add at less one authorization provider.");
        [self endLogin];
        return;
    }
    
    
    // We wait a time to make app start faster and wait until services are initialized.
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                
        NSMutableArray *authRequests = [NSMutableArray arrayWithCapacity:[providers count]];
        OKMutableInt *count = [[OKMutableInt alloc] initWithValue:(NSInteger)[providers count]];
        
        for(OKAuthProvider *provider in providers) {
            [provider getAuthRequestWithCompletion:^(OKAuthRequest *request, NSError *error) {
                
                NSAssert([NSThread mainThread], @"We are not in the main thread.");
                if(request)
                    [authRequests addObject:request];
                                
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
    
    OKLogInfo(@"OKManager: End initialization.");
    _initialized = YES;
    
    
    // At this point we can receive notifications and the user can user OKManager normally.
    // Add any observer here:
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(providerUpdated:) name:OKAuthProviderUpdatedNotification object:nil];
    [nc addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [nc addObserver:self selector:@selector(enteredBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [nc addObserver:self selector:@selector(becameAction) name:UIApplicationDidBecomeActiveNotification object:nil];
    [nc addObserver:self selector:@selector(willTerminate) name:UIApplicationWillTerminateNotification object:nil];

    
    if(_delegate && [_delegate respondsToSelector:@selector(openkitDidLaunch:)])
        [_delegate openkitDidLaunch:self];
    
    if(![self currentUser]) {
        OKLogInfo(@"OKManager: Not login in openkit.");
    }else {
        [self updatedStatus];
    }
    

    // REVIEW
    // get list of leaderboards as soon as possible
//        [OKLeaderboard syncWithCompletion:nil];
}


- (void)getLocalUserWithProvider:(OKAuthProvider*)provider
                      completion:(void(^)(OKLocalUser *user, NSError *error))handler
{
    NSParameterAssert(provider);
    NSParameterAssert(handler);
    
    [provider getAuthRequestWithCompletion:^(OKAuthRequest *request, NSError *error) {
        if(request)
            [OKLocalUser loginWithAuthRequests:@[request] completion:handler];
        else
            handler(nil, error);
    }];
}



- (void)loginWithProviderName:(NSString*)serviceName
               viewController:(UIViewController*)controller
                   completion:(void(^)(OKLocalUser *user, NSError *error))handler
{
    [self loginWithProvider:[OKAuthProvider providerByName:serviceName] 
             viewController:controller
                 completion:handler];
}


- (void)loginWithProvider:(OKAuthProvider*)provider
           viewController:(UIViewController*)controller
               completion:(void(^)(OKLocalUser *user, NSError *error))handler
{
    if(!provider)
        return;
    
    void (^connection)(BOOL, NSError*) = ^(BOOL login, NSError *err) {

        if(login) {
            if(![[self currentUser] userIDForService:[provider serviceName]]) {
                
                [self getLocalUserWithProvider:provider completion:^(OKLocalUser *user, NSError *error) {
                    if(user && !error) {
                        [self updateCachedUser];
                        [self setCurrentUser:user];
                    }
                    
                    if(handler)
                        handler(user, error);
                }];
            }
        }
        
        if(handler)
            handler([OKLocalUser currentUser], err);
    };
    
    if([provider isSessionOpen])
        connection(YES, nil);
    else
        [provider openSessionWithViewController:controller completion:connection];
}


- (void)updatedStatus
{
    OKLocalUser *user = [self currentUser];
    
    if(user) {
        OKLogInfo(@"OKManager: Logged in successfully: User id: %@", [user userID]);
        
        // update friends
        [self updateFriendsLazily:YES withCompletion:nil];
        
        // update local user data
        [user syncWithCompletion:nil];
        
        // resolve pending scores
        [OKScore resolveUnsubmittedScores];
        
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
    _currentUser = aCurrentUser;
    [self updateCachedUser];
    if([self initialized])
        [self updatedStatus];
}


- (void)updateFriendsLazily:(BOOL)lazy withCompletion:(void(^)(NSError* error))handler
{
    OKLocalUser *user = [self currentUser];
    if(!user) {
        OKLogErr(@"OKManager: We can't upload friends because we are not logged in.");
        return;
    }
    
    NSArray *providers = [OKAuthProvider getAllProviders];
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
    NSString *path = [OKFileUtil localOnlyCachePath:OK_LOCAL_USER];
    NSDictionary *dict = [OKFileUtil readSecureFile:path];
    return [OKLocalUser createUserWithDictionary:dict];
}


- (BOOL)updateCachedUser
{
    OKLocalUser *user = [self currentUser];
    if([user isAccessAllowed]) {
        OKLogInfo(@"OKManager: Updating local user in cache.");
        NSString *path = [OKFileUtil localOnlyCachePath:OK_LOCAL_USER];
        [OKFileUtil writeOnFileSecurely:[user archive] path:path];
    }
    return NO;
}


- (void)removeCachedUser
{
    NSString *path = [OKFileUtil localOnlyCachePath:OK_LOCAL_USER];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}


- (void)logoutCurrentUser
{
    OKLogInfo(@"OKManager: Logging out of openkit");
    [self removeCachedUser];
    [self setCurrentUser:nil];
    
    //[OKAuthProvider logoutAndClear];
    [OKScore clearSubmittedScore];
}


- (void)registerToken:(NSData *)deviceToken
{
    /*
    // REVIEW token
    OKLog(@"OKManager registerToken, data: %@", deviceToken);
    
    const unsigned *tokenBytes = [deviceToken bytes];
    
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];

    OKLogInfo(@"cache queue is %s", dispatch_queue_get_label(OK_CACHE_QUEUE()));
    OKLogInfo(@"Token is: %@", hexToken);
     */
}


#pragma mark - Notifications

- (void)providerUpdated:(NSNotification*)not
{
    if(![self initialized])
        OKLogErr(@"OKManager: The system was not initialized yet.");
    
    OKAuthProvider *provider = [not object];
    if([provider isSessionOpen])
        [self loginWithProvider:provider viewController:nil completion:nil];
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


#pragma mark - Private

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
