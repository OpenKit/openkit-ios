

#import "GameView.h"
#import "GameReplay.h"
#import "OpenKit.h"


@interface GameViewController ()
{
    OKGame *_game;
}
@property (weak, nonatomic) IBOutlet UIView *hero;
@property (weak, nonatomic) IBOutlet UIView *enemy;

@end
@implementation GameViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];
    [[self view] addSubview:view];
    
    
    
    UIPanGestureRecognizer* pgr = [[UIPanGestureRecognizer alloc] 
                                   initWithTarget:self
                                   action:@selector(handlePan:)];
    [self.hero addGestureRecognizer:pgr];
    
    
    /*
    UIPanGestureRecognizer* pgr2 = [[UIPanGestureRecognizer alloc] 
                                   initWithTarget:self
                                   action:@selector(handlePan2:)];
    [self.enemy addGestureRecognizer:pgr2];
    */
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _game = [[OKGame alloc] initWithDictionary:nil];
}


- (IBAction)showReplay:(id)sender
{
    GameReplayViewController *controller = [[GameReplayViewController alloc] initWithGame:_game];
    [self presentViewController:controller animated:YES completion:nil];
}


-(void)handlePan:(UIPanGestureRecognizer*)pgr
{
    if (pgr.state == UIGestureRecognizerStateChanged) {
        CGPoint center = pgr.view.center;
        CGPoint translation = [pgr translationInView:pgr.view];
        center = CGPointMake(center.x + translation.x, 
                             center.y + translation.y);
        pgr.view.center = center;
        [pgr setTranslation:CGPointZero inView:pgr.view];
        
//        [_game catchInstant:@{@"hero":
//                                  @{@"x": @(center.x),
//                                    @"y": @(center.y)}
//                              }];
        
        
        [_game catchInstant:@{@"x": @(center.x),
                              @"y": @(center.y)}];
    }
}


-(void)handlePan2:(UIPanGestureRecognizer*)pgr
{
    if (pgr.state == UIGestureRecognizerStateChanged) {
        CGPoint center = pgr.view.center;
        CGPoint translation = [pgr translationInView:pgr.view];
        center = CGPointMake(center.x + translation.x, 
                             center.y + translation.y);
        pgr.view.center = center;
        [pgr setTranslation:CGPointZero inView:pgr.view];
        
        [_game catchInstant:@{@"enemy":
                                  @{@"x": @(center.x),
                                    @"y": @(center.y)}
                              }];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
