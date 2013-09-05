//
//  OKLeaderboardsListViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/3/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "OKLeaderboardsListViewController.h"
#import "OKLeaderboardViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OKHelper.h"
#import "OKLeaderboardListCell.h"
#import "OKProfileViewController.h"
#import "OKLoginView.h"
#import "OKMacros.h"
#import "OKSocialLeaderboardViewController.h"
#import "OKColors.h"


@interface OKLeaderboardsListViewController ()

@property (nonatomic, strong) NSArray *OKLeaderBoardsList;
@property (weak, nonatomic) IBOutlet UITableView *_tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic) int defaultLeaderboardID;

@end

@implementation OKLeaderboardsListViewController

@synthesize OKLeaderBoardsList, _tableView, spinner, defaultLeaderboardID;

- (id)init {
    return [self initWithDefaultLeaderboardID:0];
}

-(id)initWithDefaultLeaderboardID:(int)leaderboardID
{
    self = [super initWithNibName:@"OKLeaderboardsListViewController" bundle:nil];
    if (self) {
        self.defaultLeaderboardID = leaderboardID;
        
        UIBarButtonItem *profileButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showProfileView)];
      
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self action:@selector(back)];
        [backButton setTitleTextAttributes:[OKColors titleTextAttributesForNavBarButton] forState:UIControlStateNormal];
      
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"close"] style:UIBarButtonItemStyleBordered target:self action:@selector(back)];
      
        [[self navigationItem] setLeftBarButtonItem:closeButton];
        [[self navigationItem] setRightBarButtonItem:profileButton];
        [[self navigationItem] setBackBarButtonItem:backButton];
    }
    return self;    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
  
    [[self navigationItem] setTitle:@"Leaderboards"];
  
    if(defaultLeaderboardID) {
        OKSocialLeaderboardViewController *vc = [[OKSocialLeaderboardViewController alloc] initWithLeaderboardID:defaultLeaderboardID];
        [[self navigationController] pushViewController:vc animated:YES];
    }
    [self getListOfLeaderboards];
}

- (IBAction)back
{
    // Have to call dismiss on presentingViewController otherwise the presenting view controller won't get the dismissViewController message, and we need the presenting view controller to get this message in OKBridgeBaseViewController
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showProfileView
{
    OKProfileViewController *profileView = [[OKProfileViewController alloc] init];
    [[self navigationController] pushViewController:profileView animated:YES];
}

- (void)getListOfLeaderboards
{
    [spinner startAnimating];
    
    [OKLeaderboard getLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, int maxPlayerCount, NSError *error) {
        
        [spinner stopAnimating];
        
        if (error) {
            OKLog(@"Error getting list of leaderboards, error: %@", error);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, but leaderboards are not available right now. Please try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
            
        } else {
            playerCount = maxPlayerCount;
            [self setOKLeaderBoardsList:leaderboards];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
      return [OKLeaderBoardsList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [indexPath row];
    static NSString *CellIdentifier = kOKLeaderboardListCellIdentifier;

    OKLeaderboardListCell *cell = (OKLeaderboardListCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil)
        cell = [[OKLeaderboardListCell alloc] init];

    [cell setBackgroundColor:[UIColor whiteColor]];
  
    [cell setLeaderboard:[OKLeaderBoardsList objectAtIndex:row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OKLeaderboard *selectedLeaderboard = [OKLeaderBoardsList objectAtIndex:[indexPath row]];
    //OKLeaderboardViewController *vc = [[OKLeaderboardViewController alloc] initWithLeaderboard:selectedLeaderboard];
    
     OKSocialLeaderboardViewController *vc = [[OKSocialLeaderboardViewController alloc] initWithLeaderboard:selectedLeaderboard];
    [[self navigationController] pushViewController:vc animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%d Leaderboards",[OKLeaderBoardsList count]];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, tableView.frame.size.width, 18)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1];
    label.font = [UIFont boldSystemFontOfSize:14];
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.text = [NSString stringWithFormat:@"%d Leaderboards",[OKLeaderBoardsList count]];
    
    [view addSubview:label];
    [view setBackgroundColor:[UIColor clearColor]]; //your background color...
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"Powered by OpenKit";
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, tableView.frame.size.width, 18)];
  label.backgroundColor = [UIColor clearColor];
  label.textAlignment = UITextAlignmentCenter;
  label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1];
  label.font = [UIFont systemFontOfSize:14];
  label.shadowColor = [UIColor whiteColor];
  label.shadowOffset = CGSizeMake(0.0, 1.0);
  label.text = @"Powered by OpenKit";
  
  [view addSubview:label];
  [view setBackgroundColor:[UIColor clearColor]];
  return view;
}

//RootViewController.m
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if ([_tableView indexPathForSelectedRow]) {
        [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
