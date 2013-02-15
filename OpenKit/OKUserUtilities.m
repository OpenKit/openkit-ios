//
//  OKUserUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/8/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKUserUtilities.h"
#import "OKManager.h"
#import "OKUser.h"
#import "OKNetworker.h"
#import "OKDefines.h"

@implementation OKUserUtilities

+ (OKUser *)createOKUserWithJSONData:(NSDictionary *)jsonData
{
    OKUser *user = [[OKUser alloc] init];
    
    NSString *_userNick = [jsonData objectForKey:@"nick"];
    NSNumber *_twitterID = [jsonData objectForKey:@"twitter_id"];
    
    if(_twitterID == (id)[NSNull null])
        _twitterID = nil;
    
    NSNumber *_OKUserID = [jsonData objectForKey:@"id"];
    
    NSNumber *_fbID = [jsonData objectForKey:@"fb_id"];
    
    if(_fbID == (id)[NSNull null])
        _fbID = nil;
    
    //NSLog(@"User dict: %@", jsonData);
    
    [user setOKUserID:_OKUserID];
    [user setUserNick:_userNick];
    [user setFbUserID:_fbID];
    [user setTwitterUserID:_twitterID];
    
    return user;
}

+ (NSDictionary *)getJSONRepresentationOfUser:(OKUser *)user
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [dict setValue:[user userNick] forKey:@"nick"];
    [dict setValue:[user twitterUserID] forKey:@"twitter_id"];
    [dict setValue:[user OKUserID] forKey:@"id"];
    [dict setValue:[user fbUserID] forKey:@"fb_id"];
    
    return dict;
}


+ (void)updateUserNickForOKUser:(OKUser *)user withNewNick:(NSString *)newNick withCompletionHandler:(void(^)(NSError *error))completionHandler
{    
    //Setup the parameters
    NSDictionary *userDict = [NSDictionary dictionaryWithObject:newNick forKey:@"nick"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userDict, @"user", nil];
    
    NSString *requestPath = [NSString stringWithFormat:@"/users/%@", [user.OKUserID stringValue]];
    
    [OKNetworker putToPath:requestPath parameters:params
                   handler:^(id responseObject, NSError *error)
     {
         if(!error){
             //Check to make sure the user was returned, that way we know the response was successful
             OKUser *responseUser = [OKUserUtilities createOKUserWithJSONData:responseObject];
             
             if([responseUser OKUserID] == [user OKUserID])
             {
                 [[OKManager sharedInstance] saveCurrentUser:responseUser];
             }
             else
             {
                 NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:@"Unknown error from OpenKit when trying to update user nick" forKey:NSLocalizedDescriptionKey];
                 error = [[NSError alloc] initWithDomain:OKErrorDomain code:0 userInfo:errorInfo];
             }
         }else{
             NSLog(@"Error updating username: %@", error);
         }
         completionHandler(error);
     }];
}
@end
