//
//  OKProfileViewController.m
//  Leaderboard
//
//  Created by Todd Hamilton on Jan/14/13.
//  Copyright (c) 2013 Todd Hamilton. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "OKProfileViewController.h"
#import "OpenKit.h"


@interface OKProfileViewController ()

@property(nonatomic, strong) IBOutlet NSMutableArray *buttons;
@property(nonatomic, strong) IBOutlet UIViewController *profilePic;
@property(nonatomic, strong) IBOutlet UILabel *nameLabel;

- (IBAction)logoutButtonPressed:(id)sender;

@end



@interface OKProfileButton : UIButton

@property(nonatomic, weak) OKAuthProvider *provider;

@end

@implementation OKProfileButton
@end

@implementation OKProfileViewController

-(id)init
{
    self = [super initWithNibName:@"OKProfileViewController" bundle:nil];
    return self;
}


- (void)load
{
    // Set name
    [[self navigationItem] setTitle:@"Settings"];
    
    NSArray *providers = [OKAuthProvider getProviders];
    self.buttons = [[NSMutableArray alloc] initWithCapacity:[providers count]];
    
    NSInteger i = 0;
    for(OKAuthProvider *provider in providers) {
        OKProfileButton *button = [[OKProfileButton alloc] initWithFrame:CGRectZero];
        [button setCenter:CGPointMake(100, 100+i*30)];
        [button setProvider:provider];
        [_buttons addObject:button];
        ++i;
    }
    
    // Update UI
    [self updateUI];
}



-(void)updateUI
{
    for(OKProfileButton *button in _buttons) {
        OKAuthProvider *provider = [button provider];
        
        NSString *text = nil;
        if([provider isSessionOpen])
            text = [NSString stringWithFormat:@"Connect %@", [provider serviceName]];
        else
            text = [NSString stringWithFormat:@"Disconnect %@", [provider serviceName]];
        
        [button setTitle:text forState: UIControlStateNormal];
    }
}


-(IBAction)logoutButtonPressed:(id)sender
{
    OKAuthProvider *provider = [(OKProfileButton*)sender provider];
    if([provider isSessionOpen])
        [provider logoutAndClear];
    else
        [provider openSessionWithViewController:self completion:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self load];
}


@end
