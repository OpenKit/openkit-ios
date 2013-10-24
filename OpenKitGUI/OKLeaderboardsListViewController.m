//
//  OKLeaderboardsListViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/3/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "OKHelper.h"
#import "OKLeaderboardListCell.h"
#import "OKLeaderboardsListViewController.h"
#import "OKProfileViewController.h"
#import "OKLoginView.h"
#import "OKMacros.h"
#import "OKSocialLeaderboardViewController.h"
#import "OKGUI.h"

@interface OKLeaderboardsListViewController ()

@property(nonatomic, strong) NSArray *leaderboards;
@property(weak, nonatomic) IBOutlet UITableView *_tableView;
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property(nonatomic) int defaultLeaderboardID;

@end


@implementation OKLeaderboardsListViewController

- (id)init
{
    self = [super initWithNibName:@"OKLeaderboardsListViewController" bundle:nil];
    if (self) {
//        
//        UIBarButtonItem *profileButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showProfileView)];

        UIBarButtonItem *profileButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(showProfileView)];
      
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(goBack)];

        [[self navigationItem] setLeftBarButtonItem:backButton];
        [[self navigationItem] setRightBarButtonItem:profileButton];
        [[self navigationItem] setBackBarButtonItem:backButton];
    }
    return self;    
}


- (void)load
{
    [[self navigationItem] setTitle:@"Leaderboards"];
    [self getListOfLeaderboards];
}


- (void)getListOfLeaderboards
{    
    BOOL sync = [OKLeaderboard getLeaderboardsWithCompletion:^(NSArray *leaderboards, NSError *error)
    {
        [_spinner stopAnimating];
        
        if (error) {
            OKLog(@"Error getting list of leaderboards, error: %@", error);
            [[[UIAlertView alloc] initWithTitle:@"Error"
                                        message:@"Sorry, but leaderboards are not available right now. Please try again later."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            
        } else {
            [self setLeaderboards:leaderboards];
            [__tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                       withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    if(!sync) {
        [_spinner startAnimating];
    }
}


#pragma mark - Callbacks

- (IBAction)goBack
{
    // Have to call dismiss on presentingViewController otherwise the presenting view controller won't get the dismissViewController message, and we need the presenting view controller to get this message in OKBridgeBaseViewController
    [OKGUI popViewController:self];
}


- (IBAction)showProfileView
{
    [OKGUI showProfileWithClose:nil];
}


#pragma mark - View methods

- (void)viewDidLoad
{
    [super viewDidLoad];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([__tableView indexPathForSelectedRow]) {
        [__tableView deselectRowAtIndexPath:[__tableView indexPathForSelectedRow] animated:animated];
    }
}



#pragma mark - TableView delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_leaderboards count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [indexPath row];
    static NSString *CellIdentifier = kOKLeaderboardListCellIdentifier;
    
    OKLeaderboardListCell *cell = (OKLeaderboardListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil)
        cell = [[OKLeaderboardListCell alloc] init];
    
    OKLeaderboard *leaderboard = _leaderboards[row];
    [cell setLeaderboard:leaderboard];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [OKGUI showLeaderboardID:[indexPath row] withClose:nil];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%d Leaderboards",[_leaderboards count]];
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Powered by OpenKit";
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

@end
