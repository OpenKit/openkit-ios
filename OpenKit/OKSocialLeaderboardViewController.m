//
//  OKSocialLeaderboardViewController.m
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSocialLeaderboardViewController.h"
#import "OKScoreCell.h"
#import "OKGKScoreWrapper.h"
#import "OKMacros.h"

#define kOKScoreCellIdentifier @"OKScoreCell"

@interface OKSocialLeaderboardViewController ()


@end

@implementation OKSocialLeaderboardViewController

@synthesize leaderboard, _tableView, moreBtn, spinner, socialScores, globalScores;

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard
{
    self = [super initWithNibName:@"OKSocialLeaderboardVC" bundle:nil];
    if (self) {
        leaderboard = aLeaderboard;
    }
    return self;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(globalScores) {
        return [globalScores count];
    } else {
        return 0;
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kOKScoreCellIdentifier;
    
    OKScoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[OKScoreCell alloc] init];
    }
    
    NSObject *score = [globalScores objectAtIndex:[indexPath row]];
    
    if([score isKindOfClass:[OKScore class]])
    {
        OKScore *okscore = (OKScore*)score;
        [cell setScore:okscore];
    } else if ([score isKindOfClass:[OKGKScoreWrapper class]]) {
        OKGKScoreWrapper *gkScoreWrapper = (OKGKScoreWrapper*)score;
        [cell setGkScoreWrapper:gkScoreWrapper];
    } else {
        //Not a GKScoreWrapper and not an OKScore
        OKLog(@"Unknown score type in social leaderboard");
    }
    
    return cell;

    
}

-(void)errorLoadingGlobalScores
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, there was an error loading the leaderboard" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [spinner startAnimating];
    [leaderboard getGlobalScoresWithPageNum:1 withCompletionHandler:^(NSArray *scores, NSError *error) {
        [spinner stopAnimating];
        if(!error && scores) {
            globalScores = [NSMutableArray arrayWithArray:scores];
            [_tableView reloadData];
        } else {
            OKLog(@"Error getting scores: %@", error);
            [self errorLoadingGlobalScores];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
