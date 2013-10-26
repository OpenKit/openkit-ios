//
//  OKSocialLeaderboardViewController.m
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSocialLeaderboardViewController.h"
#import "OpenKit.h"
#import "OKScoreCell.h"
#import "OKFBLoginCell.h"
#import "OKSpinnerCell.h"
#import "OKLoginView.h"
#import "OKGUI.h"

#define kOKScoreCellIdentifier @"OKScoreCell"

static BOOL __hasShownFBLoginPrompt = NO;


@interface OKSocialLeaderboardViewController ()

@property(nonatomic, strong) OKLeaderboard *leaderboard;
@property(nonatomic) int leaderboardID;
@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property(nonatomic, strong) MFMailComposeViewController *mail;

@property(nonatomic, strong) IBOutlet UIView *containerViewForLoadMoreButton;
@property(nonatomic, strong) IBOutlet UIButton *loadMoreScoresButton;

@property(nonatomic, strong) NSMutableArray *globalScores, *socialScores;

- (void)showActionSheet:(id)sender; //Declare method to show action sheet
- (void)showEmailUI; //Declare method to show action sheet
- (void)showMessageUI; //Declare method to show action sheet

@end


@implementation OKSocialLeaderboardViewController
{
    int numberOfSocialRequestsRunning;
    BOOL isShowingFBLoginCell;
    BOOL isShowingInviteFriendsCell;
}

static NSString *scoreCellIdentifier = kOKScoreCellIdentifier;
static NSString *fbCellIdentifier = @"OKFBLoginCell";
static NSString *spinnerCellIdentifier = @"OKSpinnerCell";
static NSString *inviteCellIdentifier = @"OKInviteCell";



- (id)initWithLeaderboardID:(int)aLeaderboardID
{
    NSParameterAssert(aLeaderboardID);
    
    self = [super initWithNibName:@"OKSocialLeaderboardVC" bundle:nil];
    if (self) {
        _leaderboardID = aLeaderboardID;
        _socialScores = [[NSMutableArray alloc] init];
        numberOfSocialRequestsRunning = 0;
        isShowingFBLoginCell = NO;
      
        //[_tableView setSeparatorColor:UIColorFromRGB(0xcacaca)];
        
        //Initialize the invite button
        //UIBarButtonItem *inviteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"invite.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showFacebookInviteUI)];
        //UIBarButtonItem *inviteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"invite.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showActionSheet:)];
        //[inviteButton setTintColor:[UIColor colorWithRed:5/255.0 green:139/255.0 blue:245/255.0 alpha:1]];
      
        UIBarButtonItem *inviteButton = [[UIBarButtonItem alloc] initWithTitle:@"Invite"
                                                                         style:UIBarButtonItemStyleDone
                                                                        target:self
                                                                        action:@selector(showFacebookInviteUI)];
        [[self navigationItem] setRightBarButtonItem:inviteButton];
    }
    return self;
}


- (void)load
{
    //Register the nib file for OKFBLoginCell
    [_tableView registerNib:[UINib nibWithNibName:@"OKFBLoginCell" bundle:[NSBundle mainBundle]]
          forCellReuseIdentifier:fbCellIdentifier];
    
    //Register the nib file for InviteCEll
    [_tableView registerNib:[UINib nibWithNibName:@"OKFBLoginCell" bundle:[NSBundle mainBundle]]
          forCellReuseIdentifier:inviteCellIdentifier];
    
    // iPad specific adjustments
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [_loadMoreScoresButton setFrame:CGRectMake(30, 0, 508, 44)];
    }
    
    
    [self getLeaderboard];
    [self showLoginPromptIfNecessary];
}


- (void)getLeaderboard
{
    BOOL sync = [OKLeaderboard getLeaderboardWithID:_leaderboardID
                                         completion:^(OKLeaderboard *leaderboard, NSError *error)
                 {
                     if(!error && leaderboard) {
                         [self setLeaderboard:leaderboard];
                     }else{
                         [[self navigationItem] setTitle:@"Error"];
                         [_spinner stopAnimating];
                         [self showErrorLoadingGlobalScores];
                     }
                 }];
    
    if(!sync) {
        // Get leaderboard instance
        [[self navigationItem] setTitle:@"loading..."];
        [_spinner startAnimating];
        [_tableView setHidden:YES];
    }
}


- (void)setLeaderboard:(OKLeaderboard *)leaderboard
{
    if(leaderboard) {
        _leaderboard = leaderboard;
        [[self navigationItem] setTitle:[_leaderboard name]];
        
        [self getGlobalScores];
        [self getSocialScores];
    }
}


- (void)getGlobalScores
{
    [_spinner startAnimating];
    [_tableView setHidden:YES];
    
    // Get global scores-- OKLeaderboard decides where to get them from
    BOOL sync = [_leaderboard getScoresForTimeRange:OKLeaderboardTimeRangeAllTime
                                         pageNumber:1
                                         completion:^(NSArray *scores, NSError *error)
    {
        [_spinner stopAnimating];
        [_tableView setHidden:NO];
        
        if(!error) {
            _globalScores = [NSMutableArray arrayWithArray:scores];
            [_tableView reloadData];
            
        } else if(error) {
            OKLog(@"Error getting global scores: %@", error);
            [self showErrorLoadingGlobalScores];
        }
    }];
    
    if(!sync) {
        [_spinner startAnimating];
        [_tableView setHidden:YES];
    }
}


- (void)getSocialScores
{
    [_spinner startAnimating];
    [_tableView setHidden:YES];
    
    BOOL sync = [_leaderboard getSocialScoresForTimeRange:OKLeaderboardTimeRangeAllTime
                                               completion:^(NSArray *scores, NSError *error)
    {
        [_spinner stopAnimating];
        [_tableView setHidden:NO];
        
        if(!error) {
            _socialScores = [NSMutableArray arrayWithArray:scores];
            [_tableView reloadData];
            
        } else if(error) {
            OKLog(@"Error getting social scores: %@", error);
            //[self showErrorLoadingGlobalScores];
        }
    }];
    
    if(!sync) {
        [_spinner startAnimating];
        [_tableView setHidden:YES];
    }
}


- (void)showLoginPromptIfNecessary
{
    if(![OKLocalUser currentUser] && !__hasShownFBLoginPrompt) {
        [OKGUI showLoginModalWithClose:^{
            [self getSocialScores];
        }];
        __hasShownFBLoginPrompt = YES;
    }
}


#pragma mark -

- (void)showActionSheet:(id)sender
{
    NSString *actionSheetTitle = @"Invite a Friend"; //Action Sheet Title
    NSString *email = @"Email";
    NSString *message = @"Message";
    NSString *facebook = @"Facebook";
    NSString *cancelTitle = @"Cancel";
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle
                                                             delegate:self
                                                    cancelButtonTitle:cancelTitle
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:email, message, facebook, nil];
    
    [actionSheet showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //Get the name of the current pressed button
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Email"]) {
        [self showEmailUI];
    }
    if ([buttonTitle isEqualToString:@"Message"]) {
        [self showMessageUI];
    }
    if ([buttonTitle isEqualToString:@"Facebook"]) {
        [self showFacebookInviteUI];
    }
    if ([buttonTitle isEqualToString:@"Cancel Button"]) {
        NSLog(@"Cancel pressed --> Cancel ActionSheet");
    }
}


- (void)showFacebookInviteUI
{
    OKAuthProvider *provider = [OKAuthProvider providerByName:@"facebook"];
    [provider openSessionWithViewController:self completion:^(BOOL login, NSError *error) {
        if(login)
            [provider performSelector:@selector(sendFacebookRequest)];
    }];
}


- (void)showEmailUI
{
    
    //Set up
    self.mail = [[MFMailComposeViewController alloc]init];
    
    _mail.mailComposeDelegate = self;
    
    //Set the subject
    [_mail setSubject:@"Check out this game"];
    
    //Set the message
    NSString * sentFrom = @"<p>Check out this game:</p>";
    [_mail setMessageBody:sentFrom isHTML:YES];
    
    [self presentViewController:_mail animated:YES completion:nil];
    
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)showMessageUI
{
	MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
	if([MFMessageComposeViewController canSendText])
	{
		controller.body = @"";
		//controller.recipients = [NSArray arrayWithObjects:@"12345678", @"87654321", nil];
		controller.messageComposeDelegate = self;
		[self presentViewController:controller animated:YES completion:nil];
	}
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MyApp" message:@"Unknown Error"
                          
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    switch (result) {
            
        case MessageComposeResultCancelled:
            NSLog(@"Cancelled");
            break;
            
        case MessageComposeResultFailed:
            [alert show];
            break;
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (BOOL)isShowingSocialScoresProgressBar {
    return (numberOfSocialRequestsRunning > 0);
}

// This method captures a lot of the logic for what type of cell is drawn at what index path so it can be reused in
// both cellForRowAtIndexPath and heightForRow
- (SocialSectionRow)getTypeOfRow:(NSIndexPath*)indexPath {
    
    int section = [indexPath section];
    int row = [indexPath row];
    
    if(section != (int)kSocialLeaderboardSection)
        return SocialSectionRowUnknownRow;
    
    if(row < [_socialScores count])
        return SocialSectionRowSocialScoreRow;
    
    if(row == [_socialScores count] && [self isShowingSocialScoresProgressBar])
        return SocialSectionRowProgressBarRow;
    
    if(row >= [_socialScores count] && isShowingFBLoginCell)
        return SocialSectionRowFBLoginRow;
    
    if([_socialScores count] == 0 && isShowingInviteFriendsCell && !isShowingFBLoginCell)
        return SocialSectionRowInviteFriends;
    
    return SocialSectionRowUnknownRow;
}


- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int numRows = 0;
    
    switch(section) {
        case kSocialLeaderboardSection:
            
            numRows = [_socialScores count];
            
            if(![OKLocalUser currentUser]) {
                numRows++;
                isShowingFBLoginCell = YES;
            }
            
            if([self isShowingSocialScoresProgressBar]) {
                numRows++;
            }
            
            if(isShowingInviteFriendsCell && !isShowingFBLoginCell && [_socialScores count] == 0)
                numRows++;
            
        case kGlobalSection:
            if(_globalScores) {
                if([self shouldShowPlayerTopScore]) {
                    return [_globalScores count] + 1;
                } else {
                    return [_globalScores count];
                }
            } else {
                return 0;
            }
        default:
            OKLog(@"Unknown section requested for rows");
            return 0;
    }
    return numRows;
}


- (UITableViewCell*)getFBLoginCell {
    OKFBLoginCell *cell =  [_tableView dequeueReusableCellWithIdentifier:fbCellIdentifier];
    if(!cell) {
        cell = [[OKFBLoginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fbCellIdentifier];
    }
    [cell setDelegate:self];
    return cell;
}


- (UITableViewCell*)getInviteFriendsCell {
    OKFBLoginCell *cell =  [_tableView dequeueReusableCellWithIdentifier:inviteCellIdentifier];
    if(!cell) {
        cell = [[OKFBLoginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:inviteCellIdentifier];
    }
    [cell setDelegate:self];
    [cell makeCellInviteFriends];
    return cell;
}


- (UITableViewCell*)getProgressBarCell
{
    OKSpinnerCell *cell = [_tableView dequeueReusableCellWithIdentifier:spinnerCellIdentifier];
    if(!cell) {
        cell = [[OKSpinnerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:spinnerCellIdentifier];
    }
    
    //[cell setBackgroundColor:[OKColors scoreCellBGColor]];
    [cell startAnimating];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}


- (UITableViewCell*)getScoreCellForPlayerTopScore:(OKScore*)score withTableView:(UITableView*)tableView
{
    OKScoreCell *cell = [self getScoreCellForScore:score withTableView:_tableView andShowSocialNetworkIcon:NO];
    //[cell setBackgroundColor:[OKColors playerTopScoreBGColor]];
    
    return cell;
}


- (OKScoreCell*)getScoreCellForScore:(OKScore*)score withTableView:(UITableView*)tableView andShowSocialNetworkIcon:(BOOL)showSocialNetworkIcon
{
    OKScoreCell *cell = [tableView dequeueReusableCellWithIdentifier:scoreCellIdentifier];
    if(!cell) {
        cell = [[OKScoreCell alloc] init];
    }
    
    //[cell setBackgroundColor:[OKColors scoreCellBGColor]];
    
    [cell setScore:score];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}


- (void)showErrorLoadingGlobalScores
{
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:@"Sorry, there was an error loading the leaderboard. Please try again later."
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles: nil] show];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self load];
}


- (BOOL)shouldShowPlayerTopScore
{
    return NO;
}


- (void)getMoreGlobalScores
{
    // If there are no scores already for this leaderboard, getting "More" doesn't make sense
    if(_globalScores == nil)
        return;
    
    int numScores = [_globalScores count];
    int currentPageNumber = numScores / NUM_SCORES_PER_PAGE;
    
    if(currentPageNumber*NUM_SCORES_PER_PAGE < numScores) {
        currentPageNumber++;
    }
    
    int nextPageNumber = currentPageNumber + 1;
    
    [_loadMoreScoresButton setEnabled:NO];
    
    [_leaderboard getScoresForTimeRange:OKLeaderboardTimeRangeAllTime
                            pageNumber:nextPageNumber
                            completion:^(NSArray *scores, NSError *error)
     {        
        if(scores != nil) {
            [_globalScores addObjectsFromArray:scores];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kGlobalSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        [_loadMoreScoresButton setEnabled:YES];
    }];
}


- (IBAction)loadMoreScoresPressed:(id)sender {
    [self getMoreGlobalScores];
}







- (void)reloadSocialScores
{
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
               withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (void)startedSocialScoreRequest
{
    numberOfSocialRequestsRunning++;
    [self reloadSocialScores];
    
}


- (void)finishedSocialScoreRequest
{
    numberOfSocialRequestsRunning--;
    
    if(numberOfSocialRequestsRunning <0)
        numberOfSocialRequestsRunning = 0;
    
    
    // If there are no social scores, and all social score requests are finished, then show
    // an invite friends
    if(numberOfSocialRequestsRunning == 0 && [_socialScores count] == 0) {
        isShowingInviteFriendsCell = YES;
    } else {
        isShowingInviteFriendsCell = NO;
    }
    
    [self reloadSocialScores];
}


#pragma mark - TableView delegate methods

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int section = [indexPath section];
    int row = [indexPath row];
    
    // REVIEW
    if(section == kGlobalSection) {
        if(row >= [_globalScores count]) {
            return [self getScoreCellForPlayerTopScore:nil withTableView:tableView];
        } else {
            return [self getScoreCellForScore:[_globalScores objectAtIndex:row] withTableView:tableView andShowSocialNetworkIcon:NO];
        }
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
                return [self getScoreCellForScore:[_socialScores objectAtIndex:row] withTableView:tableView andShowSocialNetworkIcon:YES];
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



- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case kSocialLeaderboardSection:
            return @"Friends";
        case kGlobalSection:
            return @"All Players";
        default:
            return @"";
    }
}

//-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 18;
//}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SocialSectionRow rowType = [self getTypeOfRow:indexPath];
    switch(rowType) {
            
        case SocialSectionRowFBLoginRow:
            return 60;
            break;
        case SocialSectionRowProgressBarRow:
            return 60;
            break;
        case SocialSectionRowInviteFriends:
            return 60;
            break;
        case SocialSectionRowSocialScoreRow:
            return 60;
            break;
        case SocialSectionRowUnknownRow:
            // Return empty cell to avoid crash
            return 60;
    }
    
}


@end
