//
//  OKFBLoginCell.m
//  OpenKit
//
//  Created by Suneet Shah on 6/18/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "UIImageView+Openkit.h"

@implementation UIImageView (OpenKit)

- (void)setUser:(OKUser*)user
{
    NSURL *url = [NSURL URLWithString:[user imageUrl]];
    [self setImageWithURL:url placeholderImage:[UIImage imageNamed:@"gear.png"]];
}

@end
