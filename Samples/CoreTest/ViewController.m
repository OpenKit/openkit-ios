//
//  OKViewController.m
//  SampleApp
//
//  Created by Suneet Shah on 12/26/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
#import "ViewController.h"


@implementation ViewController
{
    int _count;
}

- (id)init
{
    self = [super initWithNibName:@"ViewController" bundle:nil];
    return self;
}

- (void)startTest
{
    float waitTime = 0.2f;

    [[[self messagesView] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    _count = 0;
    // TESTING
    [self performSelector:@selector(testUpdateUser) withObject:nil afterDelay:0];
    [self performSelector:@selector(testGetLeaderboard) withObject:nil afterDelay:waitTime];
    [self performSelector:@selector(testGetScores) withObject:nil afterDelay:waitTime*2];
    [self performSelector:@selector(testPostScore) withObject:nil afterDelay:waitTime*3];
    [self performSelector:@selector(testPostAchievement) withObject:nil afterDelay:waitTime*4];
    [self performSelector:@selector(testReconnect) withObject:nil afterDelay:waitTime*5];
    
}
- (IBAction)restart:(id)sender {
    [self startTest];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self startTest];
}



- (void)postMessage:(NSString*)message error:(NSError*)error
{
    NSString *labelT = nil;
    UIColor *color = nil;
    if(error) {
        //NSLog(@"ERROR: %@: %@", message, error);
        labelT = [NSString stringWithFormat:@"ERROR: %@.", message];
        color = [UIColor redColor];
    }else{
        labelT = [NSString stringWithFormat:@"SUCCESS: %@.", message];
        color = [UIColor colorWithRed:0 green:0.6f blue:0 alpha:1.0f];
    }

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, _count*19.0f, 320, 20)];
    [label setText:labelT];
    //[label setFont:[UIFont boldSystemFontOfSize:12]];
    [label setFont:[UIFont systemFontOfSize:13]];

    [label setTextColor:color];
    [[self messagesView] addSubview:label];
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
        if([leaderboards count] > 0) {
            OKScore *score = [OKScore scoreWithLeaderboard:leaderboards[0]];
            [score setValue:rand()%1000000];
            [score submitWithCompletion:^(NSError *error) {
                [self postMessage:@"posting score" error:error];
            }];
        }
    }];
}


- (void)testPostAchievement
{
    
}


- (void)testReconnect
{
    
}





@end
