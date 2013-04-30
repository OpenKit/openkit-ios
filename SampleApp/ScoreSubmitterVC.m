//
//  ScoreSubmitterVC.m
//  SampleApp
//
//  Created by Suneet Shah on 1/9/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "ScoreSubmitterVC.h"
#import "OpenKit.h"
#import "ActionSheetStringPicker.h"

@interface ScoreSubmitterVC ()

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UIButton *submitButton;
@property (nonatomic, strong) NSArray *leaderBoards;
@property (nonatomic, strong) IBOutlet UILabel *successLabel;

@end

@implementation ScoreSubmitterVC

@synthesize spinner, textField, submitButton, leaderBoards, successLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(void)enableUI:(BOOL)enabled
{
    [submitButton setEnabled:enabled];
    [textField setEnabled:enabled];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    [spinner startAnimating];
    [self enableUI:NO];
    
    [OKLeaderboard getLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, int playerCount, NSError *error)
    {
        [spinner stopAnimating];
        if(!error)
        {
            [self setLeaderBoards:leaderboards];
            [self enableUI:YES];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error getting list of leaderboards" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }];
}

-(IBAction)close:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)startEditing:(id)sender
{
    [successLabel setHidden:YES];
}

-(IBAction)submitScore:(id)sender
{
    [successLabel setHidden:YES];
    [spinner startAnimating];
    
    NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:[leaderBoards count]];
    
    for(int x = 0; x < leaderBoards.count; x++)
    {
        [rows addObject:[(OKLeaderboard*)[leaderBoards objectAtIndex:x] name]];
    }
    
    
    [ActionSheetStringPicker showPickerWithTitle:@"Choose Leaderboard" rows:rows initialSelection:0 doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue)
    {
        OKScore *score = [[OKScore alloc] init];
        [score setScoreValue:[[textField text] integerValue]];
        [score setOKLeaderboardID:[(OKLeaderboard*)[leaderBoards objectAtIndex:selectedIndex] OKLeaderboard_id]];
        
        
        [score submitScoreWithCompletionHandler:^(NSError *error) {
            
            [spinner stopAnimating];
            
            if(error)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error submitted score" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
            else
            {
                [textField resignFirstResponder];
                [successLabel setHidden:NO];
            }
        }];


        
    } cancelBlock:^(ActionSheetStringPicker *picker) {
        return;
    } origin:sender];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
