//
//  OKLoginPopupView.m
//  OpenKit
//
//  Created by Suneet Shah on 9/19/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKLoginPopupView.h"
#import "OKGameCenterUtilities.h"

@implementation OKLoginPopupView

@synthesize loginString, gcLoginButton, fbLoginButton, spinner, delegate;

-(id)initWithLoginString:(NSString*)aLoginString
{
    self = [super initWithFrame:CGRectMake(0, 0, 280, 260)];
    if(self)
    {
        [self setLoginString:aLoginString];
        [self initLoginView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGameCenterButtonVisibility) name:OK_GAMECENTER_AUTH_NOTIFICATION object:nil];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    return [self initWithLoginString:@"test"];
}


-(void)initLoginView
{
    
    // Main Label
    CGRect mainLabelRect = self.bounds;
    mainLabelRect.origin.y = -10;
    mainLabelRect.size.height = 60;
    UIFont *mainLabelFont = [UIFont boldSystemFontOfSize:20];
    UILabel *mainLabel = [[UILabel alloc] initWithFrame:mainLabelRect];
    mainLabel.text = [self loginString];
    mainLabel.numberOfLines = 1;
    mainLabel.font = mainLabelFont;
    mainLabel.textColor = [UIColor blackColor];
    mainLabel.textAlignment = NSTextAlignmentCenter;
    mainLabel.backgroundColor = [UIColor clearColor];
    mainLabel.shadowColor = [UIColor clearColor];
    mainLabel.shadowOffset = CGSizeMake(0, 1);
    [self addSubview:mainLabel];
    
    // Sub Label
    CGRect subLabelRect = self.bounds;
    subLabelRect.origin.y = 35;
    subLabelRect.size.height = 40;
    UIFont *subLabelFont = [UIFont systemFontOfSize:14];
    UILabel *subLabel = [[UILabel alloc] initWithFrame:subLabelRect];
    NSString *subText = @"Leaderboards are more fun when you play against friends. Include friends from:";
    subLabel.text = subText;
    subLabel.numberOfLines = 2;
    subLabel.font = subLabelFont;
    subLabel.textColor = [UIColor grayColor];
    subLabel.textAlignment = NSTextAlignmentCenter;
    subLabel.backgroundColor = [UIColor clearColor];
    subLabel.shadowColor = [UIColor clearColor];
    subLabel.shadowOffset = CGSizeMake(0, 1);
    [self addSubview:subLabel];
    
    // Game Center Button
    CGRect gcButtonRect = CGRectMake(35,88,105,105);
    
    gcLoginButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [gcLoginButton setFrame:gcButtonRect];
    [gcLoginButton addTarget:self action:@selector(gcButtonPressed) forControlEvents:UIControlEventTouchDown];
    UIImage * gcButtonImageOff = [UIImage imageNamed:@"gc_off_big.png"];
    UIImage * gcButtonImageOn = [UIImage imageNamed:@"gc_on_big.png"];
    [gcLoginButton setBackgroundImage:gcButtonImageOff forState:UIControlStateNormal];
    [gcLoginButton setBackgroundImage:gcButtonImageOn forState:UIControlStateDisabled];
    
    
    [self updateGameCenterButtonVisibility];
    
    // Facebook Button
    CGRect fbButtonRect = CGRectMake(140,88,105,105);
    fbLoginButton = [UIButton buttonWithType:(UIButtonTypeCustom)];
    fbLoginButton.frame = fbButtonRect;
    [fbLoginButton addTarget:self action:@selector(fbButtonPressed) forControlEvents:UIControlEventTouchDown];
    UIImage * fbButtonImageOff = [UIImage imageNamed:@"fb_off_big.png"];
    UIImage * fbButtonImageOn = [UIImage imageNamed:@"fb_on_big.png"];
    [fbLoginButton setBackgroundImage:fbButtonImageOn forState:UIControlStateDisabled];
    [fbLoginButton setBackgroundImage:fbButtonImageOff forState:UIControlStateNormal];
    
    
    // Finished Button
    CGRect finishedButtonRect = CGRectMake(5,210,271,44);
    UIButton *finishedButton = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    [finishedButton setFrame:finishedButtonRect];
    [finishedButton addTarget:self action:@selector(finishedButtonPressed) forControlEvents:UIControlEventTouchDown];
    [finishedButton setTitle:@"Finished" forState:UIControlStateNormal];
    
    // Spinner
    float spinnerSize = 44;
    float spinnerxPos = [self bounds].size.width /2 - spinnerSize/2;
    float spinneryPos = CGRectGetMidY(self.bounds);
    CGRect spinnerRect = CGRectMake(spinnerxPos, spinneryPos, spinnerSize, spinnerSize);
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [spinner setFrame:spinnerRect];
    [spinner setColor:[UIColor darkGrayColor]];
    [spinner setHidesWhenStopped:YES];
    
    
    [self addSubview:finishedButton];
    [self addSubview:gcLoginButton];
    [self addSubview:fbLoginButton];
    [self addSubview:spinner];
}

-(void)updateGameCenterButtonVisibility
{
    if([OKGameCenterUtilities isPlayerAuthenticatedWithGameCenter]) {
        [gcLoginButton setEnabled:NO];
    } else {
        [gcLoginButton setEnabled:YES];
    }
}


-(void)fbButtonPressed {
    if(delegate) {
        [delegate fbButtonPressed];
    }
}

-(void)gcButtonPressed {
    if (delegate) {
        [delegate gcButtonPressed];
    }
}

-(void)finishedButtonPressed {
    if(delegate) {
        [delegate finishButtonPressed];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
