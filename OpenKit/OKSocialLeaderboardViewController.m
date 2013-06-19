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
#import "OKFacebookUtilities.h"
#import "OKFBLoginCell.h"

#define kOKScoreCellIdentifier @"OKScoreCell"

@interface OKSocialLeaderboardViewController ()

@end

@implementation OKSocialLeaderboardViewController

@synthesize leaderboard, _tableView, moreBtn, spinner, socialScores, globalScores;

static NSString *scoreCellIdentifier = kOKScoreCellIdentifier;
static NSString *fbCellIdentifier = @"OKFBLoginCell";

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard
{
    self = [super initWithNibName:@"OKSocialLeaderboardVC" bundle:nil];
    if (self) {
        leaderboard = aLeaderboard;
        socialScores = [[NSMutableArray alloc] init];
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
    int section = [indexPath section];
    int row = [indexPath row];
    
    if(section == kSocialLeaderboardSection && row >= [socialScores count]) {
        return 124;
    }
    else {
        return 60;
    }
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int numRowsInSocial = 0;
    
    switch(section) {
        case kSocialLeaderboardSection:
            // If we are not logged into FB then we need an extra row to show the login button
            if(![OKFacebookUtilities isFBSessionOpen]) {
                numRowsInSocial++;
            }
            
            numRowsInSocial += [socialScores count];
            return numRowsInSocial;
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
    
    int section = [indexPath section];
    int row = [indexPath row];
    
    if(section == kGlobalSection) {
        return [self getScoreCellForScore:[globalScores objectAtIndex:row] withTableView:tableView];
    }
    else if(section == kSocialLeaderboardSection) {
        if(row >= [socialScores count]) {
            return [self getFBLoginCell];
        } else {
            return [self getScoreCellForScore:[socialScores objectAtIndex:row] withTableView:tableView];
        }
    } else {
        return nil;
    }
}

-(UITableViewCell*)getFBLoginCell {
    OKFBLoginCell *cell =  [_tableView dequeueReusableCellWithIdentifier:fbCellIdentifier];
    if(!cell) {
        cell = [[OKFBLoginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fbCellIdentifier];
    }
    
    return cell;
}

-(UITableViewCell*)getScoreCellForScore:(NSObject*)score withTableView:(UITableView*)tableView
{
    OKScoreCell *cell = [tableView dequeueReusableCellWithIdentifier:scoreCellIdentifier];
    if(!cell) {
        cell = [[OKScoreCell alloc] init];
    }
    
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
    
    //Register the nib file for OKFBLoginCell
    [self._tableView registerNib:[UINib nibWithNibName:@"OKFBLoginCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:fbCellIdentifier];
    
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
    
    [self getSocialScores];
    
    // Get social scores / top score
}

//Get Social scores
-(void)getSocialScores {
    
    // If game center
    //   get GC friends scores
    // else if OKUser
    //   get top score from OpenKit
    // else
    //   get local top score
    //
    // if FB
    //   get FB scores from OpenKit
    
    if([leaderboard gamecenter_id] && [OKGameCenterUtilities gameCenterIsAvailable])
    {
        [leaderboard getGameCenterFriendsScoreswithCompletionHandler:^(NSArray *scores, NSError *error) {
            if(error) {
                OKLog(@"error getting gamecenter friends scores, %@", error);
            }
            else if(!error && scores) {
                OKLog(@"Got gamecenter friends scores");
                [self addSocialScores:scores];
            } else if ([scores count] == 0) {
                OKLog(@"Zero gamecenter friends scores returned");
            } else {
                OKLog(@"Unknown gamecenter friends scores error");
            }
        }];
    } else if ([OKUser currentUser])
    {
        [leaderboard getUsersTopScoreForLeaderboardForTimeRange:OKLeaderboardTimeRangeAllTime withCompletionHandler:^(OKScore *score, NSError *error) {
            
            if(!error && score) {
                [self addSocialScores:[NSArray arrayWithObject:score]];
            }
        }];
    }
    
    
    if([OKFacebookUtilities isFBSessionOpen]) {
        //Get facebook social scores
        
        //TODO for now faking it by getting scores from OpenKit
        
        [leaderboard getScoresForTimeRange:OKLeaderboardTimeRangeAllTime WithCompletionhandler:^(NSArray *scores, NSError *error) {
            [self addSocialScores:[scores subarrayWithRange:NSMakeRange(0, 5)]];
        }];
    }
}

-(void)addSocialScores:(NSArray *)scores
{
    if(scores) {
        [[self socialScores] addObjectsFromArray:scores];
        [_tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
