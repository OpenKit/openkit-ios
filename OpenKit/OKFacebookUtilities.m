//
//  OKFacebookUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "OKFacebookUtilities.h"
#import "OKUserUtilities.h"
#import "OKManager.h"
#import "OKNetworker.h"
#import <FacebookSDK/FBErrorUtility.h>
#import "OKMacros.h"


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

// Assuming already logged into Facebook, get's the user's ID and creates an OKUser Account with it
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

+(void)CreateOKUserWithFacebookID:(NSString *)facebookID withUserNick:(NSString *)userNick withCompletionHandler:(void(^)(OKUser *user, NSError *error))completionhandler
{
    [OKUserUtilities createOKUserWithUserIDType:FacebookIDType withUserID:facebookID withUserNick:userNick withCompletionHandler:^(OKUser *user, NSError *errror) {
        
        if(!errror) {
            // User was created successfully, save as current user
            [[OKManager sharedManager] saveCurrentUser:user];
        }
        
        // Call the passed in completionHandler
        completionhandler(user, errror);
    }];
}

// Opens a Facebook session and shows UI if necessary. Completion handler is called when session is opened, fails to open, or request is cancelled by user

+(void)OpenFBSessionWithCompletionHandler:(void(^)(NSError *error))completionHandler
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
                    completionHandler(nil);
                }
                break;
            case FBSessionStateClosed:
                NSLog(@"FBSessionStateClosed");
                //break;
            case FBSessionStateClosedLoginFailed:
                NSLog(@"FBSessionStateClosedLoginFailed");
                [FBSession.activeSession closeAndClearTokenInformation];
                
                if([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled){
                    NSLog(@"User cancelled FB login");
                    completionHandler(nil);
                } else {
                    completionHandler(error);
                }
                break;
            default:
                completionHandler(error);
                break;
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
       [self OpenFBSessionWithCompletionHandler:^(NSError *error) {
           if(error){
               // There was an error when logging in with Facebook, so let's display the error
               completionHandler(nil, error);
           } else if ([[FBSession activeSession] state] == FBSessionStateOpen) {
               // The facebook session is open so let's get the Facebook ID and create an OpenKit user
               [self GetCurrentFacebookUsersIDAndCreateOKUserWithCompletionhandler:completionHandler];
           } else {
               // No error, and also no open FB session, so user most likely cancelled
               completionHandler(nil,nil);
           }
       }];
    }
}

+(void)getListOfFriendsForCurrentUserWithCompletionHandler:(void(^)(NSArray *friends, NSError*error))completionHandler
{
    FBRequest *getFriendsRequest = [FBRequest requestForMyFriends];

    OKLog(@"Getting list of Facebook friends");
    
    [getFriendsRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if(error) {
            completionHandler(nil, error);
        }
        else {
            NSArray *friends = [result objectForKey:@"data"];
            completionHandler(friends, error);
        }
    }];
}


+(void)handleErrorLoggingIntoFacebookAndShowAlertIfNecessary:(NSError *)error
{
    NSString *alertMessage, *alertTitle;
    if (error.fberrorShouldNotifyUser) {
        // If the SDK has a message for the user, surface it. This conveniently
        // handles cases like password change or iOS6 app slider state.
        alertTitle = @"Facebook Error";
        alertMessage = error.fberrorUserMessage;
    } else if (error.fberrorCategory == FBErrorCategoryAuthenticationReopenSession) {
        // It is important to handle session closures since they can happen
        // outside of the app. You can inspect the error for more context
        // but this sample generically notifies the user.
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if (error.fberrorCategory == FBErrorCategoryUserCancelled) {
        // The user has cancelled a login. You can inspect the error
        // for more context. For this sample, we will simply ignore it.
        NSLog(@"user cancelled login");
    } else {
        // For simplicity, this sample treats other errors blindly.
        alertTitle  = @"Unknown Error";
        alertMessage = @"Error. Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}






/* OLD VERSION WITHOUT ABSTRACTION OF FACEBOOK OPEN SESSION METHOD

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
                    //break;
                case FBSessionStateClosedLoginFailed:
                    NSLog(@"FBSessionStateClosedLoginFailed");
                    [FBSession.activeSession closeAndClearTokenInformation];
                    
                    
                    if([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled){
                        NSLog(@"User cancelled FB login");
                        completionHandler(nil,nil);
                        break;
                    } else {
                        completionHandler(nil, error);
                    }
                    break;
                default:
                    completionHandler(nil, error);
                    break;
            }
            
        }];
    }
}

 
 */



+(BOOL)isFBSessionOpen {
    return ([FBSession activeSession].state == FBSessionStateOpen);
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
}



@end
