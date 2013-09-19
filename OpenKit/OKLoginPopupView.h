//
//  OKLoginPopupView.h
//  OpenKit
//
//  Created by Suneet Shah on 9/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol OKLoginPopupViewDelegate
-(void)finishButtonPressed;
-(void)fbButtonPressed;
-(void)gcButtonPressed;
@end


@interface OKLoginPopupView : UIView

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *loginString;
@property (nonatomic, strong) UIButton *fbLoginButton;
@property (nonatomic, strong) UIButton *gcLoginButton;
@property (nonatomic, weak) id<OKLoginPopupViewDelegate> delegate;

@end
