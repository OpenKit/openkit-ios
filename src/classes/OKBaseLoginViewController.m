//
//  OKBaseLoginViewController.m
//  OKClient
//
//  Created by Suneet Shah on 2/4/13.
//  Copyright (c) 2013 Suneet Shah. All rights reserved.
//

#import "OKBaseLoginViewController.h"

#import <FacebookSDK/FacebookSDK.h>
#import "OpenKit.h"
#import "OKFacebookUtilities.h"
#import "OKTwitterUtilities.h"
#import "ActionSheetStringPicker.h"
#import "KGModal.h"

@interface OKBaseLoginViewController ()

@property (nonatomic, strong) UIButton *fbLoginButton;
@property (nonatomic, strong) UIButton *twitterLoginButton;

@end

@implementation OKBaseLoginViewController

@synthesize currentTwitterAccount, twitterAccounts, loginView,spinner, fbLoginButton, twitterLoginButton, delegate;

-(id)init
{
    self = [super init];
    if(self)
    {
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
    [twitterLoginButton setHidden:YES];
}
-(void)hideLoginDialogSpinner
{
    [spinner stopAnimating];
    [fbLoginButton setHidden:NO];
    [twitterLoginButton setHidden:NO];
}


-(void)initLoginView
{
    loginView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 240)];
    
    CGRect welcomeLabelRect = loginView.bounds;
    welcomeLabelRect.origin.y = 0;
    welcomeLabelRect.size.height = 60;
    UIFont *welcomeLabelFont = [UIFont boldSystemFontOfSize:15];
    UILabel *welcomeLabel = [[UILabel alloc] initWithFrame:welcomeLabelRect];
    welcomeLabel.text = @"Create an account to access leaderboards and resume game progress from any device.";
    welcomeLabel.numberOfLines = 3;
    welcomeLabel.font = welcomeLabelFont;
    welcomeLabel.textColor = [UIColor colorWithRed:51.0f/2550.f green:51.0f/2550.f blue:51.0f/2550.f alpha:1.0];
    welcomeLabel.textAlignment = NSTextAlignmentCenter;
    welcomeLabel.backgroundColor = [UIColor clearColor];
    welcomeLabel.shadowColor = [UIColor clearColor];
    welcomeLabel.shadowOffset = CGSizeMake(0, 1);
    [loginView addSubview:welcomeLabel];
    
    CGRect fbButtonRect = CGRectMake(5,(CGRectGetMaxY(welcomeLabelRect)+20),270,44);
    fbLoginButton = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    fbLoginButton.frame = fbButtonRect;
    [fbLoginButton addTarget:self
                 action:@selector(performFacebookLogin:)
       forControlEvents:UIControlEventTouchDown];
    [fbLoginButton setTitle:@"Sign in with Facebook" forState:UIControlStateNormal];
    UIImage *fbBG = [[UIImage imageNamed:@"fbBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [fbLoginButton setBackgroundImage:fbBG forState:UIControlStateNormal];
    [fbLoginButton setTitleColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [fbLoginButton setTitleShadowColor:[UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:0.75f] forState:UIControlStateNormal];
    
    [loginView addSubview:fbLoginButton];
    
    CGRect twitterButtonRect = CGRectMake(5,(CGRectGetMaxY(fbButtonRect)+5),270,44);
    twitterLoginButton = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    twitterLoginButton.frame = twitterButtonRect;
    [twitterLoginButton addTarget:self
                      action:@selector(performTwitterLogin:)
            forControlEvents:UIControlEventTouchDown];
    [twitterLoginButton setTitle:@"Sign in with Twitter" forState:UIControlStateNormal];
    UIImage *twitterBG = [[UIImage imageNamed:@"twitterBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [twitterLoginButton setBackgroundImage:twitterBG forState:UIControlStateNormal];
    [twitterLoginButton setTitleColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [twitterLoginButton setTitleShadowColor:[UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:0.75f] forState:UIControlStateNormal];
    
    [loginView addSubview:twitterLoginButton];
    
    CGRect noThanksButtonRect = CGRectMake(5,(CGRectGetMaxY(twitterButtonRect)+10),270,44);
    UIButton *noThanksButton = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    noThanksButton.frame = noThanksButtonRect;
    [noThanksButton addTarget:self
                       action:@selector(dismissLoginView)
             forControlEvents:UIControlEventTouchDown];
    [noThanksButton setTitle:@"I don't want these features." forState:UIControlStateNormal];
    noThanksButton.titleLabel.font = [UIFont systemFontOfSize:12];
    UIImage *noThanksBG = [[UIImage imageNamed:@"noThanksBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [noThanksButton setBackgroundImage:noThanksBG forState:UIControlStateNormal];
    [noThanksButton setTitleColor:[UIColor colorWithRed:170.0f / 255.0f green:170.0f / 255.0f blue:170.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [noThanksButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    [loginView addSubview:noThanksButton];
    
    float spinnerSize = 44;
    float spinnerxPos = [loginView bounds].size.width /2 - spinnerSize/2;
    float spinneryPos = CGRectGetMidY(fbButtonRect);
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
            [self showUIToEnterNickname];
            //[self dismissModalViewControllerAnimated:YES];
        } else {
            NSLog(@"Error creating OKUser with FB authentication");
            
            if(self)
            {
            
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
            //TODO
            NSLog(@"Error logging into twitter");
        } else {
            [[OpenKit sharedInstance] saveCurrentUser:newUser];
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
    //TODO
    //Show an alert that there are no twitter accounts
    // Makes a call to SLComposeViewController or TWTweetComposeViewController(iOS5) and
    // removes subviews so the actual controller is not shown, but the alert pops up saying
    // that there are no twitter accounts and allows direct access to the "settings" page to
    // add an account.
    
    /*
    UIViewController *tweetComposer;
    
    if ([SLComposeViewController class] != nil) {
        tweetComposer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [(SLComposeViewController *)tweetComposer setCompletionHandler:^(SLComposeViewControllerResult result) {
            // do whatever you want
        }];
    } else {
        tweetComposer = [[TWTweetComposeViewController alloc] init];
        [(TWTweetComposeViewController *)tweetComposer setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
            // do whatever you want
        }];
    }
    
    for (UIView *view in [[tweetComposer view] subviews])
        [view removeFromSuperview];
    [self presentViewController:tweetComposer animated:NO completion:nil];
     */
    
    UIAlertView *noTwitterAccountsAlert = [[UIAlertView alloc] initWithTitle:@"No Twitter Accounts" message:@"You don't have any Twitter accounts stored on your device. To add a Twitter account, go to Settings --> Twitter --> Add Account, then try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [noTwitterAccountsAlert show];
}


@end
