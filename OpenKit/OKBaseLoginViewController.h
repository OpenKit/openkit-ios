//
//  OKBaseLoginViewController.h
//  OKClient
//
//  Created by Suneet Shah on 2/4/13.
//  Copyright (c) 2013 Suneet Shah. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OKNickViewController.h"

@protocol OKLoginViewDelegate <NSObject>

-(void)dismiss;

@end


@interface OKBaseLoginViewController : UIViewController<OKNickViewControllerDelegate>

@property (nonatomic, strong) NSArray *twitterAccounts;
@property (nonatomic, strong) ACAccount *currentTwitterAccount;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) id<OKLoginViewDelegate> delegate;

@property (nonatomic, strong) NSString *loginString;

-(id)initWithLoginString:(NSString*)aLoginString;
-(void)showLoginModalView;
-(void)dismissLoginView;

@end
