//
//  OKSpinnerCell.m
//  OpenKit
//
//  Created by Suneet Shah on 6/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSpinnerCell.h"


@implementation OKSpinnerCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        CGRect cellFrame = CGRectMake(0, 0, 300, 60);
        
        [self setFrame:cellFrame];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        //Resize the spinner for horizontal view
        [_spinner setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin)];
        [_spinner setCenter:CGPointMake(self.frame.size.width/2, self.frame.size.height/2)];
        [_spinner setColor:[UIColor blackColor]];
        
        [self addSubview:_spinner];
        
        //Spinner cell is not selectable
        self.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    return self;
}

- (void)startAnimating
{
    [_spinner startAnimating];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
