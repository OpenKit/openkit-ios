//
//  OKFBLoginCell.m
//  OpenKit
//
//  Created by Suneet Shah on 6/18/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKFBLoginCell.h"
#import "OKFacebookUtilities.h"
#import <FacebookSDK/FacebookSDK.h>
#import <QuartzCore/QuartzCore.h>
#import "OKMacros.h"
#import "OKColors.h"

@implementation OKFBLoginCell

@synthesize connectFBButton, textLabel, spinner, delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        //Score cell is not selectable
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

-(void)layoutSubviews {

    [super layoutSubviews];
    
}

-(void)makeCellInviteFriends
{
    [textLabel setText:@"Invite friends from"];
    
    // Move the text label up a few pixels
    CGRect textFrame = [textLabel frame];
    textFrame.origin.y = textFrame.origin.y - 5;
    [textLabel setFrame:textFrame];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)startSpinner
{
    [spinner startAnimating];
    [connectFBButton setHidden:YES];
}

-(void)stopSpinner
{
    [spinner stopAnimating];
    [connectFBButton setHidden:NO];
}

-(IBAction)connectButtonPressed:(id)sender
{
    if(delegate) {
        [delegate fbLoginButtonPressed];
    }
}





@end
