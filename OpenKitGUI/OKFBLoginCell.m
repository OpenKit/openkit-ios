//
//  OKFBLoginCell.m
//  OpenKit
//
//  Created by Suneet Shah on 6/18/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>
#import "OKFBLoginCell.h"
#import "OKFacebookUtilities.h"
#import "OKMacros.h"
#import "OKColors.h"
#import "OKUser.h"


@interface OKFBLoginCell ()

@property(nonatomic, strong) IBOutlet UILabel *textLabel;
@property(nonatomic, strong) IBOutlet UIButton *connectFBButton;
@property(nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;

- (IBAction)connectButtonPressed:(id)sender;

@end

@implementation OKFBLoginCell

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if(self) {
        //Score cell is not selectable        
    }
    
    return self;
}


-(void)layoutSubviews
{
    [super layoutSubviews];
    [self updateButtonVisibility];
}


-(void)updateButtonVisibility
{
    OKLocalUser *currentUser = [OKLocalUser currentUser];
    if(currentUser) {
        [_connectFBButton setEnabled:NO];
    } else {
        [_connectFBButton setEnabled:YES];
    }
}


- (void)makeCellInviteFriends
{
    [self.textLabel setText:@"Invite friends from"];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    // Don't show the selection blue color
    [super setSelected:NO animated:NO];
    
    // If it was selected, trigger the Facebook login action
    if(selected) {
        [self connectButtonPressed:nil];
    }
}


- (void)startSpinner
{
    [_spinner startAnimating];
    [_connectFBButton setHidden:YES];
}


- (void)stopSpinner
{
    [_spinner stopAnimating];
    [_connectFBButton setHidden:NO];
}


- (IBAction)connectButtonPressed:(id)sender
{
    if(_delegate) {
        [_delegate fbLoginButtonPressed];
    }
}

@end
