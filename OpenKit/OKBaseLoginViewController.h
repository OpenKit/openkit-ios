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

@protocol OKLoginViewDelegate <NSObject>

-(void)dismiss;

@end


@interface OKBaseLoginViewController : UIViewController

#if defined(ANDROID)
-(void) setWindow:(UIWindow *)window;
-(UIWindow*) window;
#else
@property (nonatomic, strong) UIWindow *window;
#endif
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) id<OKLoginViewDelegate> delegate;

@property (nonatomic, strong) NSString *loginString;

-(id)initWithLoginString:(NSString*)aLoginString;
-(void)showLoginModalView;
-(void)dismissLoginView;

@end
