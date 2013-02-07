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
#import "OpenKit.h"
#import "AFHTTPClient.h"

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
    NSURL *reqURL = [NSURL URLWithString:@"https://api.twitter.com/1/users/show.json?include_entities=true"];
    
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
            NSLog(@"Twitter error: %@ status code: %d", error, [urlResponse statusCode]);
            
            completionHandler(nil, nil, error);
        }
    }];
}

+(void)CreateOKUserWithTwitterID:(NSNumber *)twitterID withUserNick:(NSString *)userNick withCompletionHandler:(void(^)(OKUser *user, NSError *error))completionhandler
{
    AFHTTPClient *OK_HTTPClient = [[OpenKit sharedInstance] httpClient];
    
    //Create a request and send it to OpenKit
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:twitterID forKey:@"twitter_id"];
    [parameters setValue:[OpenKit getApplicationID] forKey:@"app_key"];
    [parameters setValue:userNick forKey:@"nick"];
    
    NSMutableURLRequest *request =  [OK_HTTPClient requestWithMethod:@"POST" path:@"/users" parameters:parameters];
    
    NSLog(@"Request is : %@ params: %@", request, parameters);
    
    AFHTTPRequestOperation *operation = [OK_HTTPClient HTTPRequestOperationWithRequest:request
                                                                               success:^(AFHTTPRequestOperation *operation, id responseObject)
                                         {
                                             //Success
                                             NSLog(@"Successfully created/found user ID: %@", [responseObject valueForKeyPath:@"id"]);
                                             OKUser *newUser = [OKUserUtilities createOKUserWithJSONData:responseObject];
                                             
                                             [[OpenKit sharedInstance] saveCurrentUser:newUser];
                                             completionhandler(newUser, nil);
                                         }
                                                                               failure:^(AFHTTPRequestOperation *operation, NSError *error)
                                         {
                                             NSLog(@"Failed to create user ");
                                             completionhandler(nil,error);
                                         }];
    
    [operation start];
}

//ithCompletionHandler:(void(^)(OKUser *user, NSError *error))completionhandler
                                                                                               
                                                                                               
@end
