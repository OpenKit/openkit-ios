//
//  OKScoreViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/14/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import "OKScoreViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OKScoreViewCell.h"


@interface OKScoreViewController ()
@end


@implementation OKScoreViewController

@synthesize currentScore, currentLeaderboard;


- (id)initWithScore:(OKScore*)aScore withLeaderboard:(OKLeaderboard*)aLeaderboard
{
    self = [super initWithNibName:@"OKScoreViewController" bundle:nil];
    if(self) {
        currentScore = aScore;
        currentLeaderboard = aLeaderboard;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Custom Facebook Button
    UIImage *fbBG = [[UIImage imageNamed:@"fbBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [self.facebookBtn setBackgroundImage:fbBG forState:UIControlStateNormal];
    [self.facebookBtn setTitleColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.facebookBtn setTitleShadowColor:[UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:0.25f] forState:UIControlStateNormal];

    // Custom Twitter Button
    UIImage *twitterBG = [[UIImage imageNamed:@"twitterBtn.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:0];
    [self.twitterBtn setBackgroundImage:twitterBG forState:UIControlStateNormal];
    [self.twitterBtn setTitleColor:[UIColor colorWithRed:255.0f / 255.0f green:255.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f] forState:UIControlStateNormal];
    [self.twitterBtn setTitleShadowColor:[UIColor colorWithRed:0.0f / 255.0f green:0.0f / 255.0f blue:0.0f / 255.0f alpha:0.25f] forState:UIControlStateNormal];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kOKScoreCellIdentifier;
    
    OKScoreViewCell *cell = (OKScoreViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil)
        cell = [[OKScoreViewCell alloc] init];
    
    [cell setScore:currentScore withLeaderboard:currentLeaderboard];
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if([[currentScore user] OKUserID] == [[OKUser currentUser] OKUserID]) {
        return @"Your High Score";
    }

    return [NSString stringWithFormat:@"%@'s High Score", [[currentScore user] userNick]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
