//
//  AppDelegate.m
//  coreTest
//
//  Created by Manuel Martinez-Almeida on 10/10/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "AppDelegate.h"
#import "OKFacebookUtilities.h"
#import "OKGameCenterPlugin.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [OKFacebookPlugin inject];
    [OKGameCenterPlugin inject];


    
    
    NSString *myAppKey = @"ySlVXskKAhallX4cUuvD";
    NSString *mySecretKey = @"n75ZgmPTS0CB3EVwRT73iSPLXMeU42f2WOpXKaTd";
    [OKManager configureWithAppKey:myAppKey secretKey:mySecretKey endpoint:@"http://api.openkit.lan:3000"];


    // Set the leaderboard list tag. By default, client asks
    // for tag = "v1". In the OpenKit dashboard, new leaderboards
    // have a default tag of "v1" as well. You can use this
    // tag feature to display different leaderboards in different
    // versions of your game. Each leaderboard can have multiple tags, but the client
    // will only display one tag.
    [[OKManager sharedManager] setLeaderboardListTag:@"v1"];
    [[OKManager sharedManager] setDelegate:self];
    
    
    self.viewController = [[UIViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window setRootViewController:self.viewController];
    [self.window makeKeyAndVisible];
    
    [self performSelector:@selector(dologin) withObject:nil afterDelay:4];
    return YES;
}

- (void)dologin
{
    [[OKFacebookPlugin inject] openSessionWithViewController:self.viewController completion:^(NSError *error) {
        NSLog(@"TRY: %@", error);
    }];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [OKManager handleOpenURL:url];
}


#pragma mark - Openkit delegate

-(void)openkitDidLaunch:(OKManager *)manager
{
    NSLog(@"Myapp: openkit launched.");
}

-(void)openkitDidChangeStatus:(OKManager *)manager
{
    if([OKLocalUser currentUser])
        NSLog(@"Myapp: connected.");
    else
        NSLog(@"Myapp: disconnected.");
}

@end
