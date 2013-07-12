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
#import "OKSpinnerCell.h"
#import "OKColors.h"

#define kOKScoreCellIdentifier @"OKScoreCell"

@interface OKSocialLeaderboardViewController ()

@end

@implementation OKSocialLeaderboardViewController
{
    int numberOfSocialRequestsRunning;
    NSIndexPath *indexPathOfFBLoginCell;
    BOOL isShowingFBLoginCell;
    BOOL isShowingInviteFriendsCell;
}

@synthesize leaderboard, _tableView, spinner, socialScores, globalScores, containerViewForLoadMoreButton, loadMoreScoresButton;

static NSString *scoreCellIdentifier = kOKScoreCellIdentifier;
static NSString *fbCellIdentifier = @"OKFBLoginCell";
static NSString *spinnerCellIdentifier = @"OKSpinnerCell";
static NSString *inviteCellIdentifier = @"OKInviteCell";

- (id)initWithLeaderboard:(OKLeaderboard *)aLeaderboard
{
    self = [super initWithNibName:@"OKSocialLeaderboardVC" bundle:nil];
    if (self) {
        leaderboard = aLeaderboard;
        socialScores = [[NSMutableArray alloc] init];
        numberOfSocialRequestsRunning = 0;
        indexPathOfFBLoginCell = nil;
        isShowingFBLoginCell = NO;
        
        
        [_tableView setSeparatorColor:UIColorFromRGB(0xb7b9bd)];
        
        
        //Initialize the invite button
        UIBarButtonItem *inviteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"invite.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSmartInviteUI)];
        [inviteButton setTintColor:[UIColor blueColor]];
        [[self navigationItem] setRightBarButtonItem:inviteButton];

    }
    return self;
}

-(void)showSmartInviteUI
{
    if([[FBSession activeSession] isOpen]) {
        [OKFacebookUtilities sendFacebookRequest];
    } else {
        [self fbLoginButtonPressed];
    }
}

// Used to keep track of tableView sections
enum Sections {
    kSocialLeaderboardSection = 0,
    kGlobalSection,
    NUM_SECTIONS
};

typedef enum {
    SocialSectionRowSocialScoreRow = 0,
    SocialSectionRowProgressBarRow,
    SocialSectionRowFBLoginRow,
    SocialSectionRowInviteFriends,
    SocialSectionRowUnknownRow
} SocialSectionRow;

-(BOOL)isShowingSocialScoresProgressBar {
    return (numberOfSocialRequestsRunning > 0);
}



-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case kSocialLeaderboardSection:
            return @"Friends";
        case kGlobalSection:
            return @"All Players";
        default:
            return @"Unknown Section";
    }
}

/*
-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(10, 0, 320, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = UIColorFromRGB(0x333333);
    label.font = [UIFont boldSystemFontOfSize:13];
    label.text = sectionTitle;
    
    UIView *view = [[UIView alloc] init];
    [view addSubview:label];
    
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30;
}
*/
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 20;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SocialSectionRow rowType = [self getTypeOfRow:indexPath];
    switch(rowType) {
            
        case SocialSectionRowFBLoginRow:
            return 115;
            break;
        case SocialSectionRowProgressBarRow:
            return 60;
            break;
        case SocialSectionRowInviteFriends:
            return 115;
            break;
        case SocialSectionRowSocialScoreRow:
            return 60;
            break;
        case SocialSectionRowUnknownRow:
            // Return empty cell to avoid crash
            return 60;
    }
    
}

// This method captures a lot of the logic for what type of cell is drawn at what index path so it can be reused in
// both cellForRowAtIndexPath and heightForRow
-(SocialSectionRow)getTypeOfRow:(NSIndexPath*)indexPath {
    
    int section = [indexPath section];
    int row = [indexPath row];
    
    if(section != (int)kSocialLeaderboardSection)
        return SocialSectionRowUnknownRow;
    
    if(row < [socialScores count])
        return SocialSectionRowSocialScoreRow;
    
    if(row == [socialScores count] && [self isShowingSocialScoresProgressBar])
        return SocialSectionRowProgressBarRow;
    
    if(row >= [socialScores count] && isShowingFBLoginCell)
        return SocialSectionRowFBLoginRow;
    
    if([socialScores count] == 0 && isShowingInviteFriendsCell && !isShowingFBLoginCell)
        return SocialSectionRowInviteFriends;
    
    return SocialSectionRowUnknownRow;
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int numRowsInSocial = 0;
    
    switch(section) {
        case kSocialLeaderboardSection:
            // If we are not logged into FB then we need an extra row to show the login button
            if(![OKFacebookUtilities isFBSessionOpen]) {
                numRowsInSocial++;
                isShowingFBLoginCell = YES;
            } else {
            }
            
            if([self isShowingSocialScoresProgressBar]) {
                numRowsInSocial++;
            }
            
            if(isShowingInviteFriendsCell && !isShowingFBLoginCell && [socialScores count] == 0)
                numRowsInSocial++;
            
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
        return [self getScoreCellForScore:[globalScores objectAtIndex:row] withTableView:tableView andShowSocialNetworkIcon:NO];
    }
    else if(section == kSocialLeaderboardSection) {
        
        SocialSectionRow rowType = [self getTypeOfRow:indexPath];
        switch(rowType) {
                
            case SocialSectionRowFBLoginRow:
                return [self getFBLoginCell];
                break;
            case SocialSectionRowProgressBarRow:
                return [self getProgressBarCell];
                break;
            case SocialSectionRowSocialScoreRow:
                return [self getScoreCellForScore:[socialScores objectAtIndex:row] withTableView:tableView andShowSocialNetworkIcon:YES];
                break;
            case SocialSectionRowInviteFriends:
                return [self getInviteFriendsCell];
                break;
            case SocialSectionRowUnknownRow:
                OKLog(@"Unknown row type returned in social scores!");
                // Return empty cell to avoid crash
                return [self getScoreCellForScore:nil withTableView:tableView andShowSocialNetworkIcon:NO];
        }
    } else {
        OKLog(@"Uknown section type in leaderboard");
        // Return empty cell to avoid crash
        return [self getScoreCellForScore:nil withTableView:tableView andShowSocialNetworkIcon:NO];;
    }
}

-(UITableViewCell*)getFBLoginCell {
    OKFBLoginCell *cell =  [_tableView dequeueReusableCellWithIdentifier:fbCellIdentifier];
    if(!cell) {
        cell = [[OKFBLoginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fbCellIdentifier];
    }
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [cell setDelegate:self];
    
    return cell;
}

-(UITableViewCell*)getInviteFriendsCell {
    OKFBLoginCell *cell =  [_tableView dequeueReusableCellWithIdentifier:inviteCellIdentifier];
    if(!cell) {
        cell = [[OKFBLoginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:inviteCellIdentifier];
    }
    [cell setDelegate:self];
    OKLog(@"Creating invite friends cell");
    [cell makeCellInviteFriends];
    
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

-(UITableViewCell*)getProgressBarCell
{
    OKSpinnerCell *cell = [_tableView dequeueReusableCellWithIdentifier:spinnerCellIdentifier];
    
    if(!cell) {
        cell = [[OKSpinnerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:spinnerCellIdentifier];
    }
    
    [cell startAnimating];
    
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}

-(UITableViewCell*)getScoreCellForScore:(id<OKScoreProtocol>)score withTableView:(UITableView*)tableView andShowSocialNetworkIcon:(BOOL)showSocialNetworkIcon
{
    OKScoreCell *cell = [tableView dequeueReusableCellWithIdentifier:scoreCellIdentifier];
    if(!cell) {
        cell = [[OKScoreCell alloc] init];
    }
    
    [cell setShowSocialNetworkIcon:showSocialNetworkIcon];
    [cell setOKScoreProtocolScore:score];
    
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
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
    
    [self setTitle:[leaderboard name]];
    
    //Get global scores
    [self getScores];
    
    //Register the nib file for OKFBLoginCell
    [self._tableView registerNib:[UINib nibWithNibName:@"OKFBLoginCell"
                                               bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:fbCellIdentifier];
    
    //Register the nib file for InviteCEll
    [self._tableView registerNib:[UINib nibWithNibName:@"OKFBLoginCell"
                                                bundle:[NSBundle mainBundle]]
          forCellReuseIdentifier:inviteCellIdentifier];
    
}

-(void)getScores
{
    [spinner startAnimating];
    [_tableView setHidden:YES];
    
    // Get global scores-- OKLeaderboard decides where to get them from
    [leaderboard getGlobalScoresWithPageNum:1 withCompletionHandler:^(NSArray *scores, NSError *error) {
        [spinner stopAnimating];
        [_tableView setHidden:NO];
        
        if(!error && scores) {
            globalScores = [NSMutableArray arrayWithArray:scores];
            [_tableView reloadData];
        } else if(error) {
            OKLog(@"Error getting global scores: %@", error);
            [self errorLoadingGlobalScores];
        }
    }];
    
    [self getSocialScores];
    
    // Get social scores / top score
}

-(void)getMoreGlobalScores
{
     // If there are no scores already for this leaderboard, getting "More" doesn't make sense
    if(globalScores == nil)
        return;
    
    int numScores = [globalScores count];
    int currentPageNumber = numScores / NUM_SCORES_PER_PAGE;
    
    if(currentPageNumber*NUM_SCORES_PER_PAGE < numScores) {
        currentPageNumber++;
    }
    
    int nextPageNumber = currentPageNumber + 1;
    
    [loadMoreScoresButton setEnabled:NO];
    
    [leaderboard getGlobalScoresWithPageNum:nextPageNumber withCompletionHandler:^(NSArray *scores, NSError *error) {
        
        if(scores != nil) {
            [globalScores addObjectsFromArray:scores];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kGlobalSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [loadMoreScoresButton setEnabled:YES];
    }];
}

-(IBAction)loadMoreScoresPressed:(id)sender
{
    [self getMoreGlobalScores];
}

-(void)fbLoginButtonPressed {
    
    if(!isShowingFBLoginCell && isShowingInviteFriendsCell)
    {
        [self showSmartInviteUI];
        return;
    }
    
    
    if([FBSession activeSession].state == FBSessionStateOpen) {
        //TODO
        OKLog(@"Fb session already open");
        [self getFacebookSocialScores];
        [OKFacebookUtilities createOrUpdateCurrentOKUserWithFB];
        isShowingFBLoginCell = NO;
        [self reloadSocialScores];
        
    } else {
        
        isShowingFBLoginCell = NO;
        [self reloadSocialScores];
        
        [OKFacebookUtilities OpenFBSessionWithCompletionHandler:^(NSError *error) {
            if ([FBSession activeSession].state == FBSessionStateOpen) {
                [self getFacebookSocialScores];
                [OKFacebookUtilities createOrUpdateCurrentOKUserWithFB];
            } else {
                [OKFacebookUtilities handleErrorLoggingIntoFacebookAndShowAlertIfNecessary:error];
                isShowingFBLoginCell = YES;
            }
            [self reloadSocialScores];
        }];
    }
}


-(void)reloadSocialScores
{
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}



//Get Social scores
-(void)getSocialScores {
    
    // If game center
    //   get GC friends scores
    // else if OKUser
    //   get top score from OpenKit
    // else
    //   get local top score (not implemented yet)
    
    //
    // if FB
    //   get FB scores from OpenKit
    
    if([leaderboard gamecenter_id] && [OKGameCenterUtilities isPlayerAuthenticatedWithGameCenter])
    {
        [self getGameCenterSocialScores];
    } else if ([OKUser currentUser]) {
        [self getUsersTopScoreFromOpenKit];
    } else {
        //TODO get local top score (not yet implemeneted)
    }
    
    if([OKFacebookUtilities isFBSessionOpen]) {
        [self getFacebookSocialScores];
    }
}

-(void)getGameCenterSocialScores {
    // Increment the counter that keeps track of requests running for social leaderboards
    [self startedSocialScoreRequest];
    
    [leaderboard getGameCenterFriendsScoreswithCompletionHandler:^(NSArray *scores, NSError *error) {
        
        // Decrement the counter that keeps track of requests running for social leaderboards
        [self finishedSocialScoreRequest];
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
}

-(void)getUsersTopScoreFromOpenKit
{
    // Increment the counter that keeps track of requests running for social leaderboards
    [self startedSocialScoreRequest];
    
    [leaderboard getUsersTopScoreForLeaderboardForTimeRange:OKLeaderboardTimeRangeAllTime withCompletionHandler:^(OKScore *score, NSError *error) {
        
        // Decrement the counter that keeps track of requests running for social leaderboards
        [self finishedSocialScoreRequest];
        
        if(!error && score) {
            [self addSocialScores:[NSArray arrayWithObject:score]];
        }
    }];
    
}

-(void)getFacebookSocialScores
{
    //Get facebook social scores
    [self startedSocialScoreRequest];
    
    [leaderboard getFacebookFriendsScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        [self addSocialScores:scores];
        isShowingFBLoginCell = NO;
        [self finishedSocialScoreRequest];
    }];
}

-(void)startedSocialScoreRequest
{
    numberOfSocialRequestsRunning++;
    [self reloadSocialScores];
    
}
-(void)finishedSocialScoreRequest
{
    numberOfSocialRequestsRunning--;
    
    if(numberOfSocialRequestsRunning <0)
        numberOfSocialRequestsRunning = 0;
    
    
    // If there are no social scores, and all social score requests are finished, then show
    // an invite friends
    if(numberOfSocialRequestsRunning == 0 && [socialScores count] == 0) {
        isShowingInviteFriendsCell = YES;
    } else {
        isShowingInviteFriendsCell = NO;
    }
    
    [self reloadSocialScores];
}

-(NSMutableArray*)sortSocialScores:(NSArray*)scores
{
    // Sort the scores
    
    NSSortDescriptor *sortDescriptor;
    
    if([leaderboard sortType] == OKLeaderboardSortTypeHighValue){
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scoreValue" ascending:NO];
    } else {
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scoreValue" ascending:YES];
    }
    
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [scores sortedArrayUsingDescriptors:sortDescriptors];
    
    NSMutableArray *mutableScores = [[NSMutableArray alloc] initWithArray:sortedArray];
    
    // Set the relative ranks
    for(int x = 0; x< [mutableScores count]; x++)
    {
        id<OKScoreProtocol> score = [mutableScores objectAtIndex:x];
        [score setRank:(x+1)];
    }
    
    return mutableScores;
}


-(void)addSocialScores:(NSArray *)scores
{
    if(scores) {
        [[self socialScores] addObjectsFromArray:scores];
        
        NSMutableArray *sortedScores = [self sortSocialScores:socialScores];
        
        [self setSocialScores:sortedScores];
    
        [_tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
