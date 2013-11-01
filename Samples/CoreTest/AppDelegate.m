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
{
    int _count;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [OKFacebookPlugin sharedInstance];
    [OKGameCenterPlugin sharedInstance];


    
    
//    NSString *myAppKey = @"ySlVXskKAhallX4cUuvD";
//    NSString *mySecretKey = @"n75ZgmPTS0CB3EVwRT73iSPLXMeU42f2WOpXKaTd";
//    [OKManager configureWithAppKey:myAppKey secretKey:mySecretKey endpoint:@"http://api.openkit.lan:3000"];

    NSString *myAppKey = @"BspfxiqMuYxNEotLeGLm";
    NSString *mySecretKey = @"2sHQOuqgwzocUdiTsTWzyQlOy1paswYLGjrdRWWf";
    
    [OKManager configureWithAppKey:myAppKey secretKey:mySecretKey];

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
    
    float waitTime = 2;
    
    _count = 0;
    // TESTING
    [self performSelector:@selector(testUpdateUser) withObject:nil afterDelay:0];
    [self performSelector:@selector(testGetLeaderboard) withObject:nil afterDelay:waitTime*2];
    [self performSelector:@selector(testGetScores) withObject:nil afterDelay:waitTime*3];
    [self performSelector:@selector(testPostScore) withObject:nil afterDelay:waitTime*4];
    [self performSelector:@selector(testPostAchievement) withObject:nil afterDelay:waitTime*5];
    [self performSelector:@selector(testReconnect) withObject:nil afterDelay:waitTime*6+2];
}


- (void)postMessage:(NSString*)message error:(NSError*)error
{
    NSString *labelT = nil;
    UIColor *color = nil;
    if(error) {
        //NSLog(@"ERROR: %@: %@", message, error);
        labelT = [NSString stringWithFormat:@"ERROR: %@. Place a breakpoint.", message];
        color = [UIColor redColor];
    }else{
        labelT = [NSString stringWithFormat:@"SUCCESS: %@.", message];
        color = [UIColor greenColor];
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 100+_count*14.0f, 320, 20)];
    [label setText:labelT];
    [label setFont:[UIFont systemFontOfSize:11]];
    [label setTextColor:color];
    [[[self viewController] view] addSubview:label];
    _count++;
}


- (void)testUpdateUser
{
    
}

- (void)testGetLeaderboard
{
    [OKLeaderboard syncWithCompletion:^(NSError *error) {
        [self postMessage:@"getting leaderboards" error:error];
    }];
}


- (void)testGetScores
{
    [OKLeaderboard getLeaderboardsWithCompletion:^(NSArray *leaderboards, NSError *error) {
        if(error) {
            [self postMessage:@"getting global scores" error:error];
        }else{
        OKLeaderboard *leaderboard = leaderboards[rand()%[leaderboards count]];
        [leaderboard getScoresForTimeRange:OKLeaderboardTimeRangeAllTime
                                pageNumber:rand()%5
                                completion:^(NSArray *scores, NSError *error) {
                                    [self postMessage:@"getting global scores" error:error];
                                }];
        }
    }];
    
    
    [OKLeaderboard getLeaderboardsWithCompletion:^(NSArray *leaderboards, NSError *error) {
        if(error) {
            [self postMessage:@"getting global scores" error:error];
        }else{
        OKLeaderboard *leaderboard = leaderboards[rand()%[leaderboards count]];
        [leaderboard getSocialScoresForTimeRange:OKLeaderboardTimeRangeAllTime
                                completion:^(NSArray *scores, NSError *error) {
                                    [self postMessage:@"getting social scores" error:error];
                                }];
        }
    }];
}


- (void)testPostScore
{
    [OKLeaderboard getLeaderboardsWithCompletion:^(NSArray *leaderboards, NSError *error) {
        OKScore *score = [OKScore scoreWithLeaderboard:leaderboards[0]];
        [score setScoreValue:rand()%1000000];
        [score submitWithCompletion:^(NSError *error) {
            [self postMessage:@"posting score." error:error];
        }];
    }];
}


- (void)testPostAchievement
{
    
}


- (void)testReconnect
{
    
}




-(void)openkitDidChangeStatus:(OKManager *)manager
{
    if([OKLocalUser currentUser])
        NSLog(@"Myapp: connected.");
    else
        NSLog(@"Myapp: disconnected.");
}

@end
