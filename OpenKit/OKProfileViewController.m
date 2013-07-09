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
  
    // Apply 4 pixel border and rounded corners to profile pic
    self.profilePic.layer.masksToBounds = YES;
    self.profilePic.layer.cornerRadius = 3.0;
    
    // Custom More Button
    UIImage *moreBG = [[UIImage imageNamed:@"grayBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [self.unlinkBtn setBackgroundImage:moreBG forState:UIControlStateNormal];
    [self.unlinkBtn setTitleColor:[UIColor colorWithRed:60.0f / 255.0f green:60.0f / 255.0f blue:60.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.unlinkBtn setTitleShadowColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    
    [self updateUI];
}

-(void)updateUI
{
    [profilePic setUser:[OKUser currentUser]];
    
    // If there is an OKUser and an Active Facebook Session, show the logout button
    if([[FBSession activeSession] isOpen] && [OKUser currentUser]){
        [self.unlinkBtn setHidden:NO];
    } else {
        [self.unlinkBtn setHidden:YES];
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
