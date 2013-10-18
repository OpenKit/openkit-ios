//
//  OKChatViewController.m
//  OpenKit
//
//  Created by Suneet Shah on 10/17/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKChatViewController.h"
#import "AFNetworking.h"

@interface OKChatViewController ()
{
    BOOL _firstTime;
    BOOL _keyboardIsDisplayed;
}
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UITextField *texBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *chatTextContainerView;
@property (strong, nonatomic) NSString *OKname;
@property (strong, nonatomic) NSNumber *OKuserID;

@end

@implementation OKChatViewController

-(id)init
{
    self = [super initWithNibName:@"OKChatVC"  bundle:nil];
    if (self) {
        _firstTime = YES;
        self.title = @"Chat";
        _keyboardIsDisplayed = NO;
    }
    
    return self;
}


- (void)scrollDown:(BOOL)animated
{
    UIScrollView *sv = self.webView.scrollView;
    CGPoint bottomOffset = CGPointMake(0, sv.contentSize.height - sv.bounds.size.height);
    [sv setContentOffset:bottomOffset animated:animated];
}

-(void)reloadChat
{
    [self.webView setAlpha:0];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://toddham.com/chat/index.php"]]];
}

- (IBAction)submit:(id)sender
{
    // REVIEW
    self.OKname = @"toddham";
    self.OKuserID = [NSNumber numberWithInt:2344];
    
    NSString *text = [self.texBar text];
    if(text.length>0) {
        
        NSURL *url = [NSURL URLWithString:@"http://toddham.com/chat"];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                self.OKname, @"name",
                                self.OKuserID, @"user_id",
                                text, @"text",
                                nil];
        
        [httpClient postPath:@"post.php" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             NSLog(@"Request Successful");
             [self.submitButton setEnabled:NO];
             [self.texBar setText:@""];
             [self reloadChat];
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"[HTTPClient Error]: %@", error.localizedDescription);
         }];
    }
}


-(void)updatePositionOfTextBarAndTextView
 {
     CGRect viewRect = [[self view] frame];
     float chatTextBarHeight = self.chatTextContainerView.frame.size.height;
     float tabBarHeight = self.tabBarController.tabBar.frame.size.height;
     float viewHeight = viewRect.size.height;
     
     float chatTextBarWidth = self.chatTextContainerView.frame.size.width;
     
     // If the keyboard is displayed, the view has been shrunk to account for the keyboard, so move to
     // the bottom of the view, otherwise move it to the bottom of the view + tabBar height
     
     CGRect newPoition;
     if(_keyboardIsDisplayed) {
         newPoition = CGRectMake(0, viewHeight - chatTextBarHeight, chatTextBarWidth, chatTextBarHeight);
     } else {
         newPoition = CGRectMake(0, viewHeight - chatTextBarHeight - tabBarHeight, chatTextBarWidth, chatTextBarHeight);
     }
     
     [[self chatTextContainerView] setFrame:newPoition];
}


-(void)viewDidLoad
{
    [super viewDidLoad];

}

#pragma mark - Events

- (IBAction)changeText:(id)sender
{
    if([[self.texBar text] length] == 0) {
        [self.submitButton setEnabled:NO];
    }else{
        [self.submitButton setEnabled:YES];
    }
    [self scrollDown:YES];
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self scrollDown:_firstTime];
    _firstTime = NO;
    
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:0
                     animations:^
     {
         [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
         webView.alpha = 1;
     } completion:nil];
}


- (void)keyboardWasShown:(NSNotification *)notification
{
    _keyboardIsDisplayed = YES;
    // Step 1: Get the size of the keyboard.
    [self scrollDown:YES];
    
    CGRect keyboardFrameInWindowsCoordinates;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrameInWindowsCoordinates];
    
    float keyboardHeight = [self getKeyboardHeightFromKeyboardFrame:keyboardFrameInWindowsCoordinates];
    
    CGRect rect = [[self view] frame];
    [[self view] setFrame:CGRectMake(0, 0, rect.size.width, rect.size.height-keyboardHeight)];
    
    [self updatePositionOfTextBarAndTextView];
}

// Need a function to get keyboard height because the CGRect returned is always the same despite
// the orientation of the device
-(float)getKeyboardHeightFromKeyboardFrame:(CGRect)keyboardFrame
{
    CGSize keyboardSize = keyboardFrame.size;
    
    float keyboardHeight;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if(UIInterfaceOrientationIsLandscape(orientation)) {
        keyboardHeight = keyboardSize.width;
    } else {
        keyboardHeight = keyboardSize.height;
    }

    return keyboardHeight;
}


- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect keyboardFrameInWindowsCoordinates;
    [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrameInWindowsCoordinates];

    float keyboardHeight = [self getKeyboardHeightFromKeyboardFrame:keyboardFrameInWindowsCoordinates];
    
    
    CGRect rect = [[self view] frame];
    CGRect newFrame = CGRectMake(0, 0, rect.size.width, rect.size.height+keyboardHeight);
    [[self view] setFrame:newFrame];
    
}

-(void)keyboardDidHide:(NSNotification*)notification
{
    _keyboardIsDisplayed = NO;
    [self updatePositionOfTextBarAndTextView];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [self reloadChat];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self reloadChat];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
