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
    }
    return self;
}

-(void)layoutSubviews {
    [connectFBButton setBackgroundColor:UIColorFromRGB(0x1c5c97)];
    [connectFBButton.layer setCornerRadius:3.0f];
    
    [connectFBButton setClipsToBounds:YES];
    
    [connectFBButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [connectFBButton setTintColor:UIColorFromRGB(0x277ac6)];
    
    //Set drop shadow 2c4372
    connectFBButton.layer.shadowColor = [UIColorFromRGB(0x2c4372) CGColor];
    connectFBButton.layer.shadowOpacity = 1.0;
    connectFBButton.layer.shadowRadius = 0;
    connectFBButton.layer.shadowOffset = CGSizeMake(2.0f, 0.0f);
    
    //[connectFBButton setBackgroundImage:[UIImage imagewith] forState:<#(UIControlState)#>]
    [super layoutSubviews];
    
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
