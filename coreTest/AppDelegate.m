//
//  AppDelegate.m
//  coreTest
//
//  Created by Manuel Martinez-Almeida on 10/10/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "AppDelegate.h"
#import "OpenKit.h"
#import "OKFacebookUtilities.h"
#import "OKGameCenterPlugin.h"
#import "OKCrypto.h"
#import "OKUtils.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [OKFacebookPlugin inject];
    [OKGameCenterPlugin inject];


    
    
    NSString *myAppKey = @"ySlVXskKAhallX4cUuvD";
    NSString *mySecretKey = @"n75ZgmPTS0CB3EVwRT73iSPLXMeU42f2WOpXKaTd";
    
    
    [OKManager configureWithAppKey:myAppKey secretKey:mySecretKey endpoint:@"http://api.openkit.lan:3000"];

    //NSString *myAppKey = @"BspfxiqMuYxNEotLeGLm";
    //NSString *mySecretKey = @"2sHQOuqgwzocUdiTsTWzyQlOy1paswYLGjrdRWWf";
    
    //[OKManager configureWithAppKey:myAppKey secretKey:mySecretKey];
    
    // Set the leaderboard list tag. By default, client asks
    // for tag = "v1". In the OpenKit dashboard, new leaderboards
    // have a default tag of "v1" as well. You can use this
    // tag feature to display different leaderboards in different
    // versions of your game. Each leaderboard can have multiple tags, but the client
    // will only display one tag.
    [[OKManager sharedManager] setLeaderboardListTag:@"v1"];
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    UIViewController *controller = [[UIViewController alloc] init];
    [self.window setRootViewController:controller];
    [self.window makeKeyAndVisible];
    
    [self performSelector:@selector(dologin) withObject:nil afterDelay:4];
    return YES;
}

- (void)dologin
{
    [[OKFacebookPlugin inject] openSessionWithViewController:self completion:^(NSError *error) {
        NSLog(@"TRY: %@", error);
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [OKManager handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
