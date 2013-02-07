//
//  OKLeaderboardViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/4/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "OKLeaderboardViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OKHelper.h"
#import "OKScoreViewController.h"

@interface OKLeaderboardViewController ()

@property (nonatomic, strong) OKScore *currentUserScore;

@end


@implementation OKLeaderboardViewController
{
    NSArray *currentlyShownLeaderboardsScores;
}

@synthesize  moreBtn, spinner, leaderboardScoresAllTime, leaderboardScoresThisWeek, leaderboardScoresToday, todayScoresButton, thisWeekScoresButton, allTimeScoresButton, currentUserScore;

/*
enum OKTableViewSections {
    kCurrentUserSection = 0,
    kTitleSection,
    kAuthorSection,
    kBodySection,
    NUM_SECTIONS
};
 */

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard
{
    self = [super initWithNibName:@"OKLeaderboardViewController" bundle:nil];
    if (self) {
        // I think the proper way to handle this is to have a leaderboard model.
        // The range property on the model dictates which view we are looking at.
        // We can do KVC on it and display the appropriate view.
        _leaderboard = aLeaderboard;
    }
    return self;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = self.leaderboard.name;

    // Custom More Button
    UIImage *moreBG = [[UIImage imageNamed:@"grayBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [self.moreBtn setBackgroundImage:moreBG forState:UIControlStateNormal];
    [self.moreBtn setTitleColor:[UIColor colorWithRed:60.0f / 255.0f green:60.0f / 255.0f blue:60.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.moreBtn setTitleShadowColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
  
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [[self navigationItem] setBackBarButtonItem:backButton];
  
    [self showAllTime:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}


#pragma mark - Actions
- (void)getScoresForTimeRange:(OKLeaderboardTimeRange)range
{
    [spinner startAnimating];
    
    [self.leaderboard getScoresForTimeRange:range WithCompletionhandler:^(NSArray *scores, NSError *error) {
        [spinner stopAnimating];
        
        if (error) {
            UIAlertView *scoresAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, but there was an error loading scores for this leaderboard. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [scoresAlert show];
        }
        else {
            
            [self getCurrentUserScoreFromScores:scores];
            
            switch (range) {
                case OKLeaderboardTimeRangeOneDay:
                    [self setLeaderboardScoresToday:scores];
                    currentlyShownLeaderboardsScores = leaderboardScoresToday;
                    break;
                case OKLeaderboardTimeRangeOneWeek:
                    [self setLeaderboardScoresThisWeek:scores];
                    currentlyShownLeaderboardsScores = leaderboardScoresThisWeek;
                    break;
                default:
                    [self setLeaderboardScoresAllTime:scores];
                    currentlyShownLeaderboardsScores = leaderboardScoresAllTime;
                    break;
            }

            [self.tableView reloadData];
        }
    }];
}

-(void)getCurrentUserScoreFromScores:(NSArray *)scores
{
    //If there is no user logged in, then return
    if(![OKUser currentUser])
        return;
    
    [self setCurrentUserScore:nil];
    
    for(int x = 0; x < [scores count]; x++)
    {
        OKScore *score = [scores objectAtIndex:x];
        
        if([[score user] OKUserID] == [[OKUser currentUser] OKUserID])
        {
            [self setCurrentUserScore:score];
            return;
        }
    }
}

-(void)setButtonAsSelected:(UIButton *)button
{
    [button setBackgroundImage:[UIImage imageNamed:@"segmented_highlight"] forState:UIControlStateNormal];
}

-(void)setButtonAsNormal:(UIButton *)button
{
    [button setBackgroundImage:nil forState:UIControlStateNormal];
}

#pragma mark - IBActions
- (IBAction)showToday:(id)sender
{
    [self setButtonAsSelected:todayScoresButton];
    [self setButtonAsNormal:thisWeekScoresButton];
    [self setButtonAsNormal:allTimeScoresButton];
    
    if(leaderboardScoresToday == nil) {
        [self getScoresForTimeRange:OKLeaderboardTimeRangeOneDay];
    }
    else {
        currentlyShownLeaderboardsScores = leaderboardScoresToday;
        [_tableView reloadData];
    }

}

- (IBAction)showThisWeek:(id)sender
{
    [self setButtonAsSelected:thisWeekScoresButton];
    [self setButtonAsNormal:todayScoresButton];
    [self setButtonAsNormal:allTimeScoresButton];
    
    if(leaderboardScoresThisWeek == nil)
    {
        [self getScoresForTimeRange:OKLeaderboardTimeRangeOneWeek];
    }
    else
    {
        currentlyShownLeaderboardsScores = leaderboardScoresThisWeek;
        [_tableView reloadData];
    }
    
}

- (IBAction)showAllTime:(id)sender
{
    [self setButtonAsSelected:allTimeScoresButton];
    [self setButtonAsNormal:thisWeekScoresButton];
    [self setButtonAsNormal:todayScoresButton];
    
    if(leaderboardScoresAllTime == nil)
    {
        [self getScoresForTimeRange:OKLeaderboardTimeRangeAllTime];
    }
    else
    {
        currentlyShownLeaderboardsScores = leaderboardScoresAllTime;
        [_tableView reloadData];
    }

}

- (IBAction)more:(id)sender
{
    NSLog(@"Just kidding!");
}



#pragma mark - UITableViewDataSource Protocol
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int numSections = [self numberOfSectionsInTableView:tableView];
    
    if(numSections == 2 && section == 0) {
        return 1;
    }
    else {
        return [currentlyShownLeaderboardsScores count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    if(currentUserScore)
        return 2;
    else
        return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kOKScoreCellIdentifier;

    int numSections = [self numberOfSectionsInTableView:tableView];
    int row = [indexPath row];
    int sectionIndex = [indexPath section];
    
    OKScoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[OKScoreCell alloc] init];
    }
    
    OKScore *selectedScore;
    
    if(numSections == 2 && sectionIndex == 0){
        selectedScore = currentUserScore;
    }
    else {
        selectedScore = [currentlyShownLeaderboardsScores objectAtIndex:row];
    }
    
    [cell setScore:selectedScore];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    int numSections = [self numberOfSectionsInTableView:tableView];
    
    switch (section) {
        case 0:
            if(numSections == 2)
                return @"Your High Score";
            else
                return [self.leaderboard playerCountString];
            break;
            
        default:
            return [self.leaderboard playerCountString];
            break;
    }
}

#pragma mark - UITableViewDelegate Protocol
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int numSections = [self numberOfSectionsInTableView:tableView];
    
    int sectionIndex = [indexPath section];
    
    OKScore *selectedScore;
    
    if(numSections == 2 && sectionIndex == 0)
    {
        selectedScore = currentUserScore;
    }
    else
    {
        selectedScore = [currentlyShownLeaderboardsScores objectAtIndex:[indexPath row]];
    }
    
    OKScoreViewController *detailView = [[OKScoreViewController alloc] initWithScore:selectedScore withLeaderboard:self.leaderboard];
    [[self navigationController] pushViewController:detailView animated:YES];

}


@end
