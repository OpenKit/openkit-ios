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

@implementation OKFBLoginCell

@synthesize connectFBButton, textLabel, spinner;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
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
    [self startSpinner];
    
    if([FBSession activeSession].state == FBSessionStateOpen) {
        //TODO
        [connectFBButton setHidden:YES];
        [textLabel setText:@"FB Session is already open"];
    } else {
        [OKFacebookUtilities OpenFBSessionWithCompletionHandler:^(NSError *error) {
            
            [self stopSpinner];
            
            if(error) {
                [OKFacebookUtilities handleErrorLoggingIntoFacebookAndShowAlertIfNecessary:error];
            } else if ([FBSession activeSession].state == FBSessionStateOpen) {
                
            }
                
        }];
    }
}





@end
