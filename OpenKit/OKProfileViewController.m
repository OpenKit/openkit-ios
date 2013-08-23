//
//  OKProfileViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/14/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "OKProfileViewController.h"
#import "OKUserProfileImageView.h"
#import <QuartzCore/QuartzCore.h>


@interface OKProfileViewController ()
@end


@implementation OKProfileViewController

@synthesize profilePic, nameLabel;

-(id)init
{
    self = [super initWithNibName:@"OKProfileViewController" bundle:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
  
    // Custom Back Button
    UIImage *backImage = [UIImage imageNamed:@"back_button"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, backImage.size.width, backImage.size.height);
  
    [backButton setImage:backImage forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonHandler:) forControlEvents:UIControlEventTouchUpInside];
  
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton] ;
  
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = backBarButtonItem;
  
    [[self navigationItem] setTitle:@"Settings"];
  
    [self updateUI];
}

- (void)backButtonHandler:(id)sender
{
  [self.navigationController popViewControllerAnimated:YES];
}

-(void)updateUI
{
    [profilePic setUser:[OKUser currentUser]];
    
    // If there is an OKUser and an Active Facebook Session, show the logout button
    if([[FBSession activeSession] isOpen] && [OKUser currentUser]){
        //[self.unlinkBtn setHidden:NO];
        [self.unlinkBtn setTitle: @"Disconnect Facebook" forState: UIControlStateNormal];
    } else {
        //[self.unlinkBtn setHidden:YES];
        [self.unlinkBtn setTitle: @"Connect Facebook" forState: UIControlStateNormal];
    }
    
     [nameLabel setText:[[OKUser currentUser] userNick]];

}


-(IBAction)logoutButtonPressed:(id)sender
{
    //[OKUser logoutCurrentUserFromOpenKit];
    [FBSession.activeSession closeAndClearTokenInformation];
    [self updateUI];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
