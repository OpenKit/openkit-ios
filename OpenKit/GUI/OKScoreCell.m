//
//  OKScoreCell.m
//  OKClient
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "OKScoreCell.h"
#import "OpenKit.h"
#import "UIImageView+Openkit.h"


@interface OKScoreCell ()

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *scoreValue;
@property (weak, nonatomic) IBOutlet UILabel *scoreRank;
//@property(nonatomic, strong) UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property(nonatomic, strong) UIImageView *socialNetworkIconImageView;
@property(nonatomic) BOOL showSocialNetworkIcon;

@end


@implementation OKScoreCell

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if(self) {
        //Score cell is not selectable
        //Score cell is not selectable
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // Initialize user icon
    }
    
    return self;
}


- (void)setScore:(OKScore *)aScore
{    
    // Update the text fields
    NSString *name = [aScore userDisplayString];
    if(!name)
        name = @"Anonymous";
    
    _name.text = name;
    _scoreValue.text = [aScore scoreDisplayString];
    _scoreRank.text = [aScore rankDisplayString];
    
    // Show the player image
    OKUser *user = [aScore user];

    [_profileImage setUser:user];

    [_profileImage.layer setMasksToBounds:YES];
    [_profileImage setBackgroundColor:[UIColor blackColor]];
    [_profileImage.layer setCornerRadius:3];
    
    NSArray *connections = [user resolveConnections];
    if([connections count] > 0){
        [_socialNetworkIconImageView setHidden:NO];
    }else{
        [_socialNetworkIconImageView setHidden:YES];
    }
}

@end
