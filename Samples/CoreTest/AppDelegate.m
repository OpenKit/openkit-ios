//
//  AppDelegate.m
//  coreTest
//
//  Created by Manuel Martinez-Almeida on 10/10/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
//#import "OKFacebookUtilities.h"
//#import "OKGameCenterPlugin.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *myAppKey = @"QveFxzg5uyV17tamwW2p";
    NSString *mySecretKey = @"PpQEr3xYmFLdVFzPHM5pAizFVNEmbrbd0aCus5os";    
    [OKManager configureWithAppKey:myAppKey secretKey:mySecretKey];
    [[OKManager sharedManager] setDelegate:self];
    
    
    self.viewController = [[ViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:self.viewController];
    [self.window makeKeyAndVisible];
    
    [self performSelector:@selector(dologin) withObject:nil afterDelay:4];
    return YES;
}

- (void)dologin
{
    //OKAuthProvider *provider = [OKAuthProvider providerByName:@"facebook"];
    //[provider openSessionWithViewController:self.viewController completion:nil];
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
