//
//  OKLoginView.m
//  OKClient
//
//  Created by Suneet Shah on 2/4/13.
//  Copyright (c) 2013 Suneet Shah. All rights reserved.
//

#import "OKLoginView.h"
#import "OpenKit.h"
#import "OKGUI.h"


@interface OKLoginButton : UIButton
@property(nonatomic, readonly) OKAuthProvider *provider;
@end


@implementation OKLoginButton

- (id)initWithProvider:(OKAuthProvider*)provider
{
    NSParameterAssert(provider);
    
    self = [super initWithFrame:CGRectMake(140,88,105,105)];
    if (self) {
        _provider = provider;
        NSString *imageOn = [NSString stringWithFormat:@"ok_%@_on.png", [provider serviceName]];
        NSString *imageOff = [NSString stringWithFormat:@"ok_%@_off.png", [provider serviceName]];
        [self setBackgroundImage:[UIImage imageNamed:imageOn] forState:UIControlStateDisabled];
        [self setBackgroundImage:[UIImage imageNamed:imageOff] forState:UIControlStateNormal];
    }
    return self;
}

@end


@interface OKLoginView()
{
    NSMutableArray *_buttons;    
}

@property (unsafe_unretained, nonatomic) IBOutlet UILabel *mainLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *secondaryLabel;

@end


@implementation OKLoginView

-(id)init
{
    return [self initWithLoginString:@"More Friends, More Fun!"];
}


-(id)initWithLoginString:(NSString *)loginString
{
    self = [super init];
    
    if(self) {
        UIView* xibView = [[[NSBundle mainBundle] loadNibNamed:@"CoverPanel" owner:self options:nil] objectAtIndex:0];
        
        [self addSubview:xibView];

        
        self.mainLabel.text = loginString;
        NSInteger i = 0;
        NSArray *providers = [OKAuthProvider getProviders];
        _buttons = [NSMutableArray arrayWithCapacity:[providers count]];
        for(OKAuthProvider *provider in providers) {
            OKLoginButton *button = [[OKLoginButton alloc] initWithProvider:provider];
            [button setCenter:CGPointMake(100, 50+50*i)];
            [button addTarget:self action:@selector(loginPressed:) forControlEvents:UIControlEventTouchUpInside];
            [_buttons addObject:button];
            [self addSubview:button];
            ++i;
        }
        [self updateUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUI)
                                                     name:OKAuthProviderUpdatedNotification
                                                   object:nil];
    }
    return self;
}


- (void)updateUI
{
    for(OKLoginButton *button in _buttons)
        [button setEnabled:![[button provider] isSessionOpen]];
}


- (void)loginPressed:(id)sender
{
    OKAuthProvider *provider = [(OKLoginButton*)sender provider];
    [provider openSessionWithViewController:nil completion:nil];
}


- (IBAction)finishedPressed:(id)sender
{
    [OKGUI popModal:self];
}

@end
