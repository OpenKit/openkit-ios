//
//  OKFacebookUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "OpenKit.h"
#import "OKFacebookUtilities.h"
#import "OKUserUtilities.h"


@implementation OKFacebookUtilities

+(BOOL)handleOpenURL:(NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

+(void)handleDidBecomeActive
{
    [FBSession.activeSession handleDidBecomeActive];
}

+(void)handleWillTerminate
{
    [FBSession.activeSession close];
}

+(void)GetCurrentFacebookUsersIDAndCreateOKUserWithCompletionhandler:(void(^)(OKUser *user, NSError *error))compHandler
{
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        // Did everything come back okay with no errors?
        if (!error && result)
        {
            NSString *fbUserID = [result id];
            NSString *userNick = [result name];
            
            [OKFacebookUtilities CreateOKUserWithFacebookID:fbUserID withUserNick:userNick withCompletionHandler:^(OKUser *user, NSError *error) {
                if(user && !error)
                {
                    //TODO user found
                    compHandler(user, nil);
                }
                else
                {
                    //TODO user not found
                    compHandler(nil,error);
                }
            }];
        }
        else
        {
            //Error performing the FB request
            compHandler(nil, error);
        }
    }];
}



+(void)AuthorizeUserWithFacebookWithCompletionHandler:(void(^)(OKUser *user, NSError *error))completionHandler
{
    if([[FBSession activeSession] state] == FBSessionStateOpen)
    {
        NSLog(@"FBSessionStateOpen, just making request to get user ID");
        [self GetCurrentFacebookUsersIDAndCreateOKUserWithCompletionhandler:completionHandler];
    }
    else
    {
        [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
            
            switch(status)
            {
                case FBSessionStateOpen:
                    NSLog(@"FBSessionStateOpen");
                    if(!error)
                    {
                        //We have a valid session
                        NSLog(@"Facebook user session found/opened successfully");
                        // Get the user's facebook ID
                        [self GetCurrentFacebookUsersIDAndCreateOKUserWithCompletionhandler:completionHandler];
                    }
                    break;
                case FBSessionStateClosed:
                    NSLog(@"FBSessionStateClosed");
                    NSLog(@"FB Session is closed but user token is cached, it will try to reopen session, don't throw an error yet. ");
                    //completionHandler(nil, error);
                    //break;
                case FBSessionStateClosedLoginFailed:
                    NSLog(@"FBSessionStateClosedLoginFailed");
                    [FBSession.activeSession closeAndClearTokenInformation];
                    completionHandler(nil, error);
                    break;
                default:
                    completionHandler(nil, error);
                    break;
            }
            
        }];
    }
}

+(void)CreateOKUserWithFacebookID:(NSString *)facebookID withUserNick:(NSString *)userNick withCompletionHandler:(void(^)(OKUser *user, NSError *error))completionhandler
{
    AFHTTPClient *OK_HTTPClient = [[OpenKit sharedInstance] httpClient];
    
    //Create a request and send it to OpenKit
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setValue:facebookID forKey:@"fb_id"];
    [parameters setValue:[OpenKit getApplicationID] forKey:@"app_key"];
    [parameters setValue:userNick forKey:@"nick"];
    
    NSMutableURLRequest *request =  [OK_HTTPClient requestWithMethod:@"POST" path:@"/users" parameters:parameters];
    
    AFHTTPRequestOperation *operation = [OK_HTTPClient HTTPRequestOperationWithRequest:request
                                                                               success:^(AFHTTPRequestOperation *operation, id responseObject)
                                         {
                                             //Success
                                             NSLog(@"Successfully created/found user ID: %@", [responseObject valueForKeyPath:@"id"]);
                                             OKUser *newUser = [OKUserUtilities createOKUserWithJSONData:responseObject];
                                             
                                             //TODO save current user
                                             [[OpenKit sharedInstance] saveCurrentUser:newUser];
                                             completionhandler(newUser, nil);
                                         }
                                                                               failure:^(AFHTTPRequestOperation *operation, NSError *error)
                                         {
                                             NSLog(@"Failed to create user with error: %@", error);
                                             completionhandler(nil,error);
                                         }];
    
    [operation start];
}


// Returns YES if a cached session was found and opened, NO if not
+(BOOL)OpenCachedFBSessionWithoutLoginUI
{
    BOOL foundCachedSession = [FBSession openActiveSessionWithAllowLoginUI:NO];
    
    if(foundCachedSession)
    {
        NSLog(@"Opened cached FB session");
    }
    
    return foundCachedSession;
}

+(BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI
{
    return [FBSession openActiveSessionWithReadPermissions:nil allowLoginUI:allowLoginUI completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
        [self sessionStateChanged:session state:status error:error];
    }];
}

+(void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error
{
    switch(state)
    {
        case FBSessionStateOpen:
            if(!error)
            {
                //We have a valid session
                NSLog(@"Facebook user session found/opened successfully");
            }
            break;
        case FBSessionStateClosed:
            break;
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    /*
    
    if (error)
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
     */
}



@end
