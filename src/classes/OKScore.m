//
//  OKScore.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScore.h"
#import "OKUserUtilities.h"
#import "OKUser.h"
#import "OKDirector.h"
#import "OKNetworker.h"

@implementation OKScore

@synthesize OKLeaderboardID, OKScoreID, scoreValue, user, scoreRank;

- (id)initFromJSON:(NSDictionary*)jsonDict
{
    self = [super init];
    if (self) {
        // Initialization code here.
        
        self.OKLeaderboardID = [[jsonDict objectForKey:@"leaderboard_id"] integerValue];
        self.OKScoreID = [[jsonDict objectForKey:@"id"] integerValue];
        self.scoreValue = [[jsonDict objectForKey:@"value"] integerValue];
        self.scoreRank = [[jsonDict objectForKey:@"rank"] integerValue];
        self.user = [OKUserUtilities createOKUserWithJSONData:[jsonDict objectForKey:@"user"]];
    }
    
    return self;
}

-(NSDictionary*)getScoreParamDict
{
    OKUser *currentUser = [[OpenKit sharedInstance] currentUser];
    
    NSMutableDictionary *paramDict = [[NSMutableDictionary alloc] initWithCapacity:3];
    
    [paramDict setValue:[NSNumber numberWithInt:scoreValue] forKey:@"value"];
    [paramDict setValue:[NSNumber numberWithInt:OKLeaderboardID] forKey:@"leaderboard_id"];
    [paramDict setValue:[currentUser OKUserID] forKey:@"user_id"];
    
    return paramDict;
}

-(void)submitScoreWithCompletionHandler:(void (^)(NSError *error))completionHandler
{
    //Can only submit scores for the currently logged in user
    [self setUser:[OKUser currentUser]];
    
    if (!user) {
        NSError *noUserError = [[NSError alloc] initWithDomain:OKErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObject:@"No user is logged into openkit. To submit a score, there must be a currently logged in user" forKey:NSLocalizedDescriptionKey]];
        completionHandler(noUserError);
    }
    
    //Create a request and send it to OpenKit
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                             [self getScoreParamDict], @"score", nil];
    
    [OKNetworker postToPath:@"/scores" parameters:params
                    handler:^(id responseObject, NSError *error)
     {
         if(!error) {
             NSLog(@"Successfully posted score");
             NSLog(@"Response: %@", responseObject);
         }else{
             NSLog(@"Failed to post score");
             NSLog(@"Error: %@", error);
         }
         completionHandler(error);
     }];
}


@end
