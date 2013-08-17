//
//  OKBaseLoginViewController.m
//  OKClient
//
//  Created by Suneet Shah on 2/4/13.
//  Copyright (c) 2013 Suneet Shah. All rights reserved.
//

#import "OKBaseLoginViewController.h"

#import <FacebookSDK/FacebookSDK.h>
#import "OKManager.h"
#import "OKFacebookUtilities.h"
#import "OKTwitterUtilities.h"
#import "ActionSheetStringPicker.h"
#import "KGModal.h"

@interface OKBaseLoginViewController ()

@property (nonatomic, strong) UIButton *fbLoginButton;
@property (nonatomic, strong) UIButton *gcLoginButton;
@property (nonatomic, strong) UIButton *twitterLoginButton;

@end

@implementation OKBaseLoginViewController

@synthesize currentTwitterAccount, twitterAccounts, loginView,spinner, fbLoginButton, gcLoginButton, twitterLoginButton, delegate, loginString;

-(id)initWithLoginString:(NSString*)aLoginString
{
    self = [super init];
    if(self)
    {
        [self setLoginString:aLoginString];
        [self initLoginView];
    }
    return self;
}

- (void)loadView{
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
}

-(void)showLoginModalView
{
    KGModal *modal = [KGModal sharedInstance];
    [modal setTapOutsideToDismiss:NO];
    [modal setShowCloseButton:NO];
    [modal showWithContentView:loginView andAnimated:YES];
    [modal setDelegate:self];
}
-(void)dismissLoginView
{
    [[KGModal sharedInstance] hide];
    [[KGModal sharedInstance] setDelegate:nil];
    [delegate dismiss];
}

-(void)showLoginDialogSpinner
{
    [spinner startAnimating];
    [fbLoginButton setHidden:YES];
    //[twitterLoginButton setHidden:YES];
}
-(void)hideLoginDialogSpinner
{
    [spinner stopAnimating];
    [fbLoginButton setHidden:NO];
    //[twitterLoginButton setHidden:NO];
}


-(void)initLoginView
{
    loginView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 260)];
  
    // Main Label
    CGRect mainLabelRect = loginView.bounds;
    mainLabelRect.origin.y = -10;
    mainLabelRect.size.height = 60;
    UIFont *mainLabelFont = [UIFont boldSystemFontOfSize:20];
    UILabel *mainLabel = [[UILabel alloc] initWithFrame:mainLabelRect];
    mainLabel.text = [self loginString];
    mainLabel.numberOfLines = 1;
    mainLabel.font = mainLabelFont;
    mainLabel.textColor = [UIColor blackColor];
    mainLabel.textAlignment = NSTextAlignmentCenter;
    mainLabel.backgroundColor = [UIColor clearColor];
    mainLabel.shadowColor = [UIColor clearColor];
    mainLabel.shadowOffset = CGSizeMake(0, 1);
    [loginView addSubview:mainLabel];
  
    // Sub Label
    CGRect subLabelRect = loginView.bounds;
    subLabelRect.origin.y = 35;
    subLabelRect.size.height = 40;
    UIFont *subLabelFont = [UIFont systemFontOfSize:14];
    UILabel *subLabel = [[UILabel alloc] initWithFrame:subLabelRect];
    NSString *subText = @"Leaderboards are more fun when you play against friends. Include friends from:";
    subLabel.text = subText;
    subLabel.numberOfLines = 2;
    subLabel.font = subLabelFont;
    subLabel.textColor = [UIColor grayColor];
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.backgroundColor = [UIColor clearColor];
    subLabel.shadowColor = [UIColor clearColor];
    subLabel.shadowOffset = CGSizeMake(0, 1);
    [loginView addSubview:subLabel];
  
    // Game Center Button
    CGRect gcButtonRect = CGRectMake(35,88,105,105);
    gcLoginButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    gcLoginButton.frame = gcButtonRect;
    [gcLoginButton addTarget:self
                      action:nil
            forControlEvents:UIControlEventTouchDown];
    UIImage * gcButtonImage = [UIImage imageNamed:@"gamecenter_off_big"];
    [gcLoginButton setBackgroundImage:gcButtonImage forState:UIControlStateNormal];
    
    [loginView addSubview:gcLoginButton];
  
    // Facebook Button
    CGRect fbButtonRect = CGRectMake(140,88,105,105);
    fbLoginButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    fbLoginButton.frame = fbButtonRect;
    [fbLoginButton addTarget:self
                 action:@selector(performFacebookLogin:)
       forControlEvents:UIControlEventTouchDown];
    //[fbLoginButton setTitle:@"Facebook" forState:UIControlStateNormal];
    UIImage * fbButtonImage = [UIImage imageNamed:@"facebook_off_big"];
    [fbLoginButton setBackgroundImage:fbButtonImage forState:UIControlStateNormal];
    
    [loginView addSubview:fbLoginButton];
  
    // Finished Button
    CGRect finishedButtonRect = CGRectMake(5,210,271,44);
    UIButton *finishedButton = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    finishedButton.frame = finishedButtonRect;
    [finishedButton addTarget:self
                       action:@selector(dismissLoginView)
             forControlEvents:UIControlEventTouchDown];
    [finishedButton setTitle:@"Finished" forState:UIControlStateNormal];
    
    [loginView addSubview:finishedButton];
    
    float spinnerSize = 44;
    float spinnerxPos = [loginView bounds].size.width /2 - spinnerSize/2;
    float spinneryPos = CGRectGetMidY(loginView.bounds);
    CGRect spinnerRect = CGRectMake(spinnerxPos, spinneryPos, spinnerSize, spinnerSize);
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [spinner setFrame:spinnerRect];
    [spinner setColor:[UIColor darkGrayColor]];
    [spinner setHidesWhenStopped:YES];
    [loginView addSubview:spinner];
    
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)performFacebookLogin:(id)sender
{
    [self showLoginDialogSpinner];
    
    [OKFacebookUtilities AuthorizeUserWithFacebookWithCompletionHandler:^(OKUser *user, NSError *error) {
        [self hideLoginDialogSpinner];
        
        if (user) {
            //Logged into OpenKit Successfully
            [self showUIToEnterNickname];
        } else {
            //Did not login to OpenKit, could be a cancelled process
            
            if(error)
            {
                NSLog(@"OpenKit Error: Could not create OKUser with FB authentication: %@", error.description);
                
                UIAlertView *fbLoginErrorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, there was an error logging you in through Facebook. Please try again later or try logging in with a Twitter account" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [fbLoginErrorAlert show];
            }
            
        }
    }];
}

- (IBAction)performTwitterLogin:(id)sender
{
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [store requestAccessToAccountsWithType:twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
        
        if (error) {
            if ([error code] == 6) {
                //No Twitter accounts defined
                [self performSelectorOnMainThread:@selector(showAlertForZeroTwitterAccounts) withObject:nil waitUntilDone:NO];
            }
            return;
        }
        
        if (!granted) {
            NSLog(@"User did not grant twitter account access");
            [self performSelectorOnMainThread:@selector(showAlertForAccessNotGranted) withObject:nil waitUntilDone:NO];
            return;
        } else {
            //Twitter account access granted
            NSArray *aTwitterAccounts = [store accountsWithAccountType:twitterAccountType];
            
            [self setTwitterAccounts:aTwitterAccounts];
            
            if ([twitterAccounts count] == 0) {
                //Another check for no accounts defined (not sure if this gets reached)
                NSLog(@"No twitter accounts!");
                [self performSelectorOnMainThread:@selector(showAlertForZeroTwitterAccounts) withObject:nil waitUntilDone:NO];
                return;
            } else {
                if([twitterAccounts count] > 1) {
                    //Show UI to pick a Twitter account from the list
                    [self performSelectorOnMainThread:@selector(displayUIToPickFromMultipleTwitterAccounts:) withObject:sender waitUntilDone:NO];
                    return;
                }
                
                ACAccount *account = [twitterAccounts objectAtIndex:0];
                [self setCurrentTwitterAccount:account];
                [self showLoginDialogSpinner];
                [self loginWithTwitterAccount:account];
            }
        }
        
    }];
}

- (void)loginWithTwitterAccount:(ACAccount *)account
{
    [self showLoginDialogSpinner];
    
    [OKTwitterUtilities AuthorizeTwitterAccount:account withCompletionHandler:^(OKUser *newUser, NSError *error) {
        [self hideLoginDialogSpinner];
        
        if (error) {            
            NSLog(@"Error logging into twitter: %@",error);
        } else {
            [[OKManager sharedManager] saveCurrentUser:newUser];
            NSLog(@"Logged in with Twitter");
            [self showUIToEnterNickname];
            //[self dismissModalViewControllerAnimated:YES];
        }
    }];
}

- (void)didFinishShowingNickVC
{
    //[self.presentingViewController dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        [delegate dismiss];
    }];
}


- (void)showUIToEnterNickname
{
    [[KGModal sharedInstance] hideAnimated:YES withCompletionBlock:^{
        OKNickViewController *nickVC = [[OKNickViewController alloc] init];
        [nickVC setDelegate:self];
        [self presentModalViewController:nickVC animated:NO];
    }];
}

- (void)displayUIToPickFromMultipleTwitterAccounts:(id)sender
{
    NSMutableArray *twitterAccountStrings = [[NSMutableArray alloc] initWithCapacity:[twitterAccounts count]];
    
    for (int x = 0; x < [twitterAccounts count]; x++) {
        NSString *accountString = [NSString stringWithFormat:@"@%@", [[twitterAccounts objectAtIndex:x] username]];
        [twitterAccountStrings addObject:accountString];
    }
    
    
    [ActionSheetStringPicker showPickerWithTitle:@"Choose an account" rows:twitterAccountStrings initialSelection:0
                                       doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                           NSLog(@"Picked a twitter acount account");
                                           ACAccount *selectedAccount = [twitterAccounts objectAtIndex:selectedIndex];
                                           [self loginWithTwitterAccount:selectedAccount];
                                       } cancelBlock:^(ActionSheetStringPicker *picker) {
                                           NSLog(@"Canceled");
                                       } origin:sender];
}

- (void)showAlertForAccessNotGranted
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected"
                                                    message:@"You didn't grant access to a Twitter account. Please grant access or sign in with a Facebook account."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)showAlertForZeroTwitterAccounts
{
    
    UIAlertView *noTwitterAccountsAlert = [[UIAlertView alloc] initWithTitle:@"No Twitter Accounts" message:@"You don't have any Twitter accounts stored on your device. To add a Twitter account, go to Settings --> Twitter --> Add Account, then try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [noTwitterAccountsAlert show];
}


@end
