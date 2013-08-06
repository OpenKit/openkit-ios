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
#import "OKMacros.h"

@interface OKLeaderboardViewController ()

@property (nonatomic, strong) OKScore *topScoreAllTime;
@property (nonatomic, strong) OKScore *topScoreThisWeek;
@property (nonatomic, strong) OKScore *topScoreToday;

@end


@implementation OKLeaderboardViewController
{
    NSArray *currentlyShownLeaderboardsScores;
}

@synthesize  moreBtn, spinner, leaderboardScoresAllTime, leaderboardScoresThisWeek, leaderboardScoresToday, todayScoresButton, thisWeekScoresButton, allTimeScoresButton, topScoreAllTime, topScoreThisWeek, topScoreToday;


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
            
            NSMutableArray *mutableScores = [[NSMutableArray alloc] initWithArray:scores];
            
            switch (range) {
                case OKLeaderboardTimeRangeOneDay:
                    [self setLeaderboardScoresToday:mutableScores];
                    currentlyShownLeaderboardsScores = leaderboardScoresToday;
                    break;
                case OKLeaderboardTimeRangeOneWeek:
                    [self setLeaderboardScoresThisWeek:mutableScores];
                    currentlyShownLeaderboardsScores = leaderboardScoresThisWeek;
                    break;
                default:
                    [self setLeaderboardScoresAllTime:mutableScores];
                    currentlyShownLeaderboardsScores = leaderboardScoresAllTime;
                    break;
            }

            [self.tableView reloadData];
        }
    }];
    
    [self.leaderboard getPlayerTopScoreForLeaderboardForTimeRange:range
                                           withCompletionHandler:^(OKScore *score, NSError *error)
    {
        if(!error) {
            
            [self setTopScore:score forTimeRange:range];
            [_tableView reloadData];
        }
        else {
            OKLog(@"Error getting user's top score: %@",error);
        }
        
    }];
}

-(void)getMoreScoresForTimeRange:(OKLeaderboardTimeRange)range
{
    NSArray *scores = [self getCachedScoresForRange:range];
    
    // If there are no scores already for this leaderboard, getting "More" doesn't make sense
    if(scores == nil)
        return;
    
    int numScores = [scores count];
    int currentPageNumber = numScores / NUM_SCORES_PER_PAGE;
    if(currentPageNumber*NUM_SCORES_PER_PAGE < numScores) { 
        currentPageNumber++;
    }
    
    int nextPageNumber = currentPageNumber + 1;
    
    [moreBtn setEnabled:NO];
    
    [self.leaderboard getScoresForTimeRange:currentDisplayedLeaderboardTimeRange forPageNumber:nextPageNumber WithCompletionhandler:^(NSArray *scores, NSError *error) {
        
        NSMutableArray *mutableScores = [self getCachedScoresForRange:range];
        [mutableScores addObjectsFromArray:scores];
        [_tableView reloadData];
        
        [moreBtn setEnabled:YES];
    }];
    
}

-(NSMutableArray*)getCachedScoresForRange:(OKLeaderboardTimeRange)range
{
    switch (range) {
        case OKLeaderboardTimeRangeOneDay:
            return leaderboardScoresToday;
        case OKLeaderboardTimeRangeOneWeek:
            return leaderboardScoresThisWeek;
        default:
            return leaderboardScoresAllTime;
    }
}


-(OKScore*)getTopScoreForRange:(OKLeaderboardTimeRange)range
{
    switch (range) {
        case OKLeaderboardTimeRangeOneDay:
            return topScoreToday;
        case OKLeaderboardTimeRangeOneWeek:
            return topScoreThisWeek;
        default:
            return topScoreAllTime;
    }
}

-(void)setTopScore:(OKScore*)score forTimeRange:(OKLeaderboardTimeRange)range
{
    switch (range) {
        case OKLeaderboardTimeRangeOneDay:
            topScoreToday = score;
            break;
        case OKLeaderboardTimeRangeOneWeek:
            topScoreThisWeek = score;
            break;
        default:
            topScoreAllTime = score;
            break;
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
    
     currentDisplayedLeaderboardTimeRange = OKLeaderboardTimeRangeOneDay;
    
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
    
     currentDisplayedLeaderboardTimeRange = OKLeaderboardTimeRangeOneWeek;
    
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
    
    currentDisplayedLeaderboardTimeRange = OKLeaderboardTimeRangeAllTime;
    
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
    [self getMoreScoresForTimeRange:currentDisplayedLeaderboardTimeRange];
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
    
    if([self getTopScoreForRange:currentDisplayedLeaderboardTimeRange] != nil) {
        return 2;
    }
    else {
        return 1;
    }
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
        selectedScore = [self getTopScoreForRange:currentDisplayedLeaderboardTimeRange];
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



/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int numSections = [self numberOfSectionsInTableView:tableView];
    
    int sectionIndex = [indexPath section];
    
    OKScore *selectedScore;
    
    if(numSections == 2 && sectionIndex == 0)
    {
        selectedScore = [self getTopScoreForRange:currentDisplayedLeaderboardTimeRange];
    }
    else
    {
        selectedScore = [currentlyShownLeaderboardsScores objectAtIndex:[indexPath row]];
    }
    
    OKScoreViewController *detailView = [[OKScoreViewController alloc] initWithScore:selectedScore withLeaderboard:self.leaderboard];
    [[self navigationController] pushViewController:detailView animated:YES];

}
 */


@end
