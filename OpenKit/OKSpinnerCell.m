//
//  OKSpinnerCell.m
//  OpenKit
//
//  Created by Suneet Shah on 6/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSpinnerCell.h"

@implementation OKSpinnerCell

@synthesize spinner;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        CGRect cellFrame = CGRectMake(0, 0, 300, 60);
        //CGRect labelFrame = CGRectMake(100, 20, 20, 20);
        
        CGRect spinnerFrame = CGRectMake(150, 20, 20, 20);
    
        [self setFrame:cellFrame];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
        [spinner setColor:[UIColor blackColor]];
        [spinner setFrame:spinnerFrame];
        
        [self addSubview:spinner];
        //[self bringSubviewToFront:spinner];
        
        /*
        
        UILabel *label3 = [[UILabel alloc] initWithFrame:labelFrame];
        label3.tag = 3;
        label3.font = [UIFont boldSystemFontOfSize:15];
        label3.backgroundColor = [UIColor clearColor];
        label3.textAlignment = NSTextAlignmentCenter;
        label3.adjustsFontSizeToFitWidth = YES;
        label3.text = @"S";
        [self addSubview:label3];
         */

    }
    return self;
}

- (void)startAnimating {
    [spinner startAnimating];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
