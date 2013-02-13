//
//  OKProfileViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/14/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "OKProfileViewController.h"
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
    self.profilePic.layer.cornerRadius = 30.0;
    //[self.profilePic.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    //[self.profilePic.layer setBorderWidth: 4.0];
    
    [profilePic setUser:[OKUser currentUser]];
  
    // Custom More Button
    UIImage *moreBG = [[UIImage imageNamed:@"grayBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [self.unlinkBtn setBackgroundImage:moreBG forState:UIControlStateNormal];
    [self.unlinkBtn setTitleColor:[UIColor colorWithRed:60.0f / 255.0f green:60.0f / 255.0f blue:60.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.unlinkBtn setTitleShadowColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    
    [nameLabel setText:[[OKUser currentUser] userNick]];
}


-(IBAction)logoutButtonPressed:(id)sender
{
    [OKUser logoutCurrentUserFromOpenKit];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
