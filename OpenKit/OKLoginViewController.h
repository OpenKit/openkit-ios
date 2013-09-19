//
//  OKLoginViewController.h
//  OpenKit
//
//  Created by Suneet Shah on 9/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKLoginPopupView.h"

@interface OKLoginViewController : UIViewController<OKLoginPopupViewDelegate>

@property (nonatomic, strong) OKLoginPopupView *popupView;
@property (nonatomic, strong) UIWindow *window;

-(void)showPopup;

@end
