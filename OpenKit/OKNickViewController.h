//
//  OKNickViewController.h
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/2/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OKNickViewControllerDelegate;


@interface OKNickViewController : UIViewController

@property (weak) id<OKNickViewControllerDelegate> delegate;

- (IBAction)back;

@end


@protocol OKNickViewControllerDelegate <NSObject>
@required
- (void)didFinishShowingNickVC;
@end
