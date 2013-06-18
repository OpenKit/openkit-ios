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
#import "OKGameCenterUtilities.h"

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

// Used to keep track of tableView sections
enum Sections {
    kSocialLeaderboardSection = 0,
    kGlobalSection,
    NUM_SECTIONS
};

enum SocialSectionRows {
    kLocalScoreSection = 0,
    kFB
};


-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case kSocialLeaderboardSection:
            return @"Friends";
        case kGlobalSection:
            return @"All Scores";
        default:
            return @"Unknown Section";
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section) {
        case kSocialLeaderboardSection:
            return 0;
        case kGlobalSection:
            if(globalScores) {
                return [globalScores count];
            } else {
                return 0;
            }
        default:
            OKLog(@"Unknown section requested for rows");
            return 0;
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kOKScoreCellIdentifier;
    
    int section = [indexPath section];
    
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
    
    //Get global scores
    [self getScores];
    
   }

-(void)getScores
{
    [spinner startAnimating];
    
    // Get global scores-- OKLeaderboard decides where to get them from
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
    
    // Get social scores / top score
}

-(void)getSocialScores {
    if([leaderboard gamecenter_id] && [OKGameCenterUtilities gameCenterIsAvailable])
    {
        [leaderboard getGameCenterFriendsScoreswithCompletionHandler:^(NSArray *scores, NSError *error) {
            if(error) {
                OKLog(@"error getting gamecenter friends scores, %@", error);
            }
            else if(!error && scores) {
                OKLog(@"Got gamecenter friends scores");
                
            } else if ([scores count] == 0) {
                OKLog(@"Zero gamecenter friends scores returned");
            } else {
                OKLog(@"Unknown gamecenter friends scores error");
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
