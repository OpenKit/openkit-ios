//
//  OKFBLoginCell.h
//  OpenKit
//
//  Created by Suneet Shah on 6/18/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol OKFBLoginCellDelegate <NSObject>

- (void)fbLoginButtonPressed;

@end


@interface OKFBLoginCell : UITableViewCell

@property(nonatomic, weak) id<OKFBLoginCellDelegate> delegate;

- (void)makeCellInviteFriends;

@end
