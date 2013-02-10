//
//  OKAppDelegate.m
//  SampleApp
//
//  Created by Suneet Shah on 12/26/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKAppDelegate.h"
#import "OpenKit.h"
#import "OKViewController.h"

//#import "OKCloud.h"
//#import <objc/runtime.h>

NSString *const OK_FBSessionStateChangedNotification = @"OK_FBSessionStateChangedNotification";


@implementation OKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Always enter your app key in didFinishLaunchingWithOptions
#ifdef LOCAL_SERVER
    [OpenKit initializeWithAppID:@"ZGa5rreNauqPLHsLY6Yz"];
    [OpenKit setEndpoint:@"http://localhost:3000"];
#else
    [OpenKit initializeWithAppID:@"VwfMRAl5Gc4tirjw"];
    [OpenKit setEndpoint:@"http://stage.openkit.io"];
#endif


    // Set root view controller.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[OKViewController alloc] init];
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    self.window.rootViewController = navi;
    [self.window makeKeyAndVisible];

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [OpenKit handleOpenURL:url];
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [OpenKit handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [OpenKit handleWillTerminate];
}

@end
