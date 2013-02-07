//
//  OKNickViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/2/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "OKNickViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OpenKit.h"
#import "OKUserUtilities.h"
#import "OKHelper.h"


@interface OKNickViewController ()

@property (strong, nonatomic) IBOutlet UITextField *nickField;
@property (strong, nonatomic) IBOutlet UIButton *doneBtn;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet OKUserProfileImageView *profilePic;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)doneButtonPressed:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;

@end


@implementation OKNickViewController

@synthesize nickField, doneBtn, profilePic, nameLabel, spinner, scrollView, navBar, delegate;

- (IBAction)back
{
    /*
    [self dismissViewControllerAnimated:NO completion:^{
        [delegate didFinishShowingNickVC];
    }];
     */
    [delegate didFinishShowingNickVC];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init
{
    self = [super initWithNibName:@"OKNickViewController" bundle:nil];
    if (self) {
        //custom init
    }
    return self;
}

- (void)updateForUser:(OKUser *)user
{
    [self.profilePic setUser:user];
    [self.nickField setText:[user userNick]];
    [self.nameLabel setText:[user userNick]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
  
    [[self navBar] setBarStyle:UIBarStyleBlack];
  
    [self updateForUser:[OKUser currentUser]];
  
    // Apply 4 pixel border and rounded corners to profile pic
    self.profilePic.layer.masksToBounds = YES;
    self.profilePic.layer.cornerRadius = 30.0;
    //[self.profilePic.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    //[self.profilePic.layer setBorderWidth: 4.0];
  
    // Apply custom styles to textInput
    self.nickField.layer.masksToBounds=YES;
    CGRect frameRect = self.nickField.frame;
    frameRect.size.height = 44;
    self.nickField.frame = frameRect;
    self.nickField.backgroundColor = [UIColor whiteColor];
    self.nickField.layer.cornerRadius=8.0f;
    self.nickField.borderStyle = UITextBorderStyleNone;
    self.nickField.layer.borderWidth = 1.0f;
    self.nickField.layer.borderColor = [[UIColor colorWithRed:176.0f / 255.0f green:176.0f / 255.0f blue:176.0f / 255.0f alpha:1.0f] CGColor];

    // Apply padding to textInput
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    self.nickField.leftView = paddingView;
    self.nickField.leftViewMode = UITextFieldViewModeAlways;
  
    // Custom Done Button
    UIImage *doneBG = [[UIImage imageNamed:@"doneBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [self.doneBtn setBackgroundImage:doneBG forState:UIControlStateNormal];
    [self.doneBtn setTitleColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.doneBtn setTitleShadowColor:[UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:0.75f] forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    // Step 1: Get the size of the keyboard.
    //CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect keyboardFrameInWindowsCoordinates;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrameInWindowsCoordinates];
    CGSize keyboardSize = keyboardFrameInWindowsCoordinates.size;
    
    CGRect aRect = self.view.frame;
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(orientation)) {
        float width = keyboardSize.width;
        keyboardSize.width = keyboardSize.height;
        keyboardSize.height = width;
        
        float viewWidth = aRect.size.width;
        aRect.size.width = aRect.size.height;
        aRect.size.height = viewWidth;
    }
        
    // Step 2: Adjust the bottom content inset of your scroll view by the keyboard height.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    // Step 3: Scroll the target text field into view.
    aRect.size.height -= keyboardSize.height;

    CGPoint bottomLeftpoint = CGPointMake(doneBtn.frame.origin.x, doneBtn.frame.origin.y + doneBtn.frame.size.height);

    if (!CGRectContainsPoint(aRect, bottomLeftpoint)) {
        CGPoint scrollPoint = CGPointMake(0.0, bottomLeftpoint.y - (keyboardSize.height-15));
        [scrollView setContentOffset:scrollPoint animated:YES];
    }}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    /*
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
     */
}

- (IBAction)dismissKeyboard:(id)sender
{
    [nickField resignFirstResponder];
}

- (IBAction)doneButtonPressed:(id)sender
{
    NSString *userNickEntered = [nickField text];
    
    //If the user pressed done but did not change their nickname, then do nothing
    if ([userNickEntered isEqualToString:[[OKUser currentUser] userNick]]) {
        [delegate didFinishShowingNickVC];
    } else if (![self isValidNickname:userNickEntered]) {
        UIAlertView *invalidNickAlert = [[UIAlertView alloc] initWithTitle:@"Invalid Nick" message:@"Please enter a nickname or skip to use the name provided by your account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [invalidNickAlert show];
    } else {
        [spinner startAnimating];
        [doneBtn setHidden:YES];
        
        [OKUserUtilities updateUserNickForOKUser:[OKUser currentUser] withNewNick:userNickEntered
                           withCompletionHandler:^(NSError *error)
        {
            [spinner stopAnimating];
            [doneBtn setHidden:NO];
            
            if(error) {
                //There was an error updating your nickname
                UIAlertView *nickUpdateErrorAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an error updating your nickname. You can try again or do it later from your profile" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [nickUpdateErrorAlert show];
            }
            else {
                [delegate didFinishShowingNickVC];
            }
        }];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Method that validates whether the nick is a valid nick
// For now just checks for empty string
- (BOOL)isValidNickname:(NSString *)nick
{
    return ![nick isEqualToString:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
