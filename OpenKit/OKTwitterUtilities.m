//
//  OKTwitterUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Twitter/Twitter.h>
#import "OKTwitterUtilities.h"
#import "OKUserUtilities.h"
#import "OKManager.h"
#import "OKNetworker.h"

@implementation OKTwitterUtilities

+(void)AuthorizeTwitterAccount:(ACAccount *)twitterAccount withCompletionHandler:(void(^)(OKUser *newUser, NSError *error))completionHandler
{
    [self GetTwitterUserInfoFromTwitterAccount:twitterAccount withCompletionHandler:^(NSNumber *twitterID, NSString *userNick, NSError *error) {
        if(error)
        {
            completionHandler(nil, error);
        }
        else
        {
            [self CreateOKUserWithTwitterID:twitterID withUserNick:userNick withCompletionHandler:^(OKUser *user, NSError *error) {
                if(error)
                {
                    completionHandler(nil, error);
                }
                else
                {
                    completionHandler(user, nil);
                }
            }];
        }
        
    }];
}

+(void)GetProfileImageURLFromTwitterUserID:(NSString *)twitterID
{
    NSURL *reqURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/users/show.json?include_entities=true"];
    
    NSDictionary *params = [NSDictionary dictionaryWithObject:twitterID forKey:@"user_id"];
    
    TWRequest *request = [[TWRequest alloc] initWithURL:reqURL parameters:params requestMethod:TWRequestMethodGET];
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if([urlResponse statusCode] == 200)
        {
            NSError *error;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            NSLog(@"Twitter response: %@", dict);
        }
        else
        {
            NSLog(@"Twitter error: %@ status code: %d", error, [urlResponse statusCode]);
        }
    }];
}

+(void)GetTwitterUserInfoFromTwitterAccount:(ACAccount *)twitterAccount withCompletionHandler:(void(^)(NSNumber *twitterID, NSString *userNick, NSError *error))completionHandler
{
    //NSURL *reqURL = [NSURL URLWithString:@"https://api.twitter.com/1/users/show.json?include_entities=true"];
    
    //Changed request URL to v1.1 of twitter API
    NSURL *reqURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
    
    
    NSDictionary *params = [NSDictionary dictionaryWithObject:[twitterAccount username] forKey:@"screen_name"];
    TWRequest *request = [[TWRequest alloc] initWithURL:reqURL parameters:params requestMethod:TWRequestMethodGET];
    
    [request setAccount:twitterAccount];
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        if([urlResponse statusCode] == 200)
        {
            NSError *error;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            NSLog(@"Twitter response: %@", dict);
            
            NSNumber *twitterID = [dict objectForKey:@"id"];
            NSString *userNick = [dict objectForKey:@"name"];
            
            completionHandler(twitterID, userNick, nil);
        }
        else
        {
            if(!error)
                error = [NSError errorWithDomain:@"TwitterError" code:[urlResponse statusCode] userInfo:nil];
            
            NSLog(@"Twitter error: %@ status code: %d", error, [urlResponse statusCode]);
            
            completionHandler(nil, nil, error);
        }
    }];
}

+(void)CreateOKUserWithTwitterID:(NSNumber *)twitterID withUserNick:(NSString *)userNick withCompletionHandler:(void(^)(OKUser *user, NSError *error))completionhandler
{
    [OKUserUtilities createOKUserWithUserIDType:TwitterIDType withUserID:[twitterID stringValue] withUserNick:userNick withCompletionHandler:^(OKUser *user, NSError *errror) {
        
        if(!errror) {
            //Save the current user if request was successful
            [[OKManager sharedManager] saveCurrentUser:user];
        }
        
        //Call the passed in completionHandler
        completionhandler(user, errror);
    }];
}
                                                                                               
                                                                                               
@end
