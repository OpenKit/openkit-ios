//
//  CloudDataTestVC.m
//  SampleApp
//
//  Created by Louis Zell on 1/30/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "CloudDataTestVC.h"
#import "OKCloud.h"
#import "OpenKit.h"


@implementation CloudDataTestVC

-(void)viewDidLoad
{
    [[self navigationItem] setTitle:@"Cloud Data Test"];
    
    if(![OKUser currentUser])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You must be logged into OpenKit to test cloud data" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (IBAction)storeString:(id)sender
{
    [OKCloud set:@"Hello World" key:@"firstKey" completion:^(id obj, NSError *err) {
        if (!err) {
            NSLog(@"Successfully set string: %@", obj);
        } else {
            NSLog(@"Error setting string! %@", err);
        }
    }];
}

- (IBAction)retrieveString:(id)sender
{
    [OKCloud get:@"firstKey" completion:^(id obj, NSError *err) {
        if (!err) {
            NSLog(@"Successfully got: %@", obj);
        } else {
            NSLog(@"Error getting string! %@", err);
        }
    }];
}

- (IBAction)storeDict:(id)sender
{
    NSArray *arr = [NSArray arrayWithObjects:@"one", @"two", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"foo",                           @"property1",
                          [NSNumber numberWithInt:-99],     @"property2",
                          [NSNumber numberWithBool:YES],    @"property3",
                          arr,                              @"property4",
                          nil];

    [OKCloud set:dict key:@"secondKey" completion:^(id obj, NSError *err) {
        if (!err) {
            NSLog(@"Successfully set dictionary: %@", obj);
        } else {
            NSLog(@"Error setting dictionary! %@", err);
        }
    }];
}

- (IBAction)retrieveDict:(id)sender
{
    [OKCloud get:@"secondKey" completion:^(id obj, NSError *err) {
        if (!err) {
            NSLog(@"Successfully got: %@", obj);
            NSLog(@"Class of property1: %@", [[obj objectForKey:@"property1"] class]);
            NSLog(@"Class of property2: %@", [[obj objectForKey:@"property2"] class]);
            NSLog(@"Class of property3: %@", [[obj objectForKey:@"property3"] class]);
            NSLog(@"Class of property4: %@", [[obj objectForKey:@"property4"] class]);
        } else {
            NSLog(@"Error getting dictionary! %@", err);
        }
    }];
}



@end
