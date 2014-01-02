//
//  OKFacebookUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/FBErrorUtility.h>
#import "OKFacebookPlugin.h"
#import "OKManager.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKHelper.h"
#import "OKNotifications.h"


@implementation OKFacebookPlugin

+ (BOOL)handleOpenURL:(NSURL *)url
{
    return [[FBSession activeSession] handleOpenURL:url];
}

+ (void)handleDidBecomeActive
{
    [[FBSession activeSession] handleDidBecomeActive];
}

+ (void)handleWillTerminate
{
    [[FBSession activeSession] close];
}


+ (NSString*)serviceName
{
    return @"facebook";
}

+ (BOOL)shouldInject
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FacebookAppID"] != nil;
}

+ (BOOL)isUIVisible
{
    return YES;
}


+ (BOOL)isSessionOpen
{
    return [[FBSession activeSession] state] == FBSessionStateOpen;
}


+ (BOOL)start
{
    return [self openSessionWithViewController:nil completion:nil];
}


+ (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler
{
    if([self isSessionOpen]) {
        if(handler)
            handler(YES, nil);
        return YES;
    }
    
    return [FBSession openActiveSessionWithReadPermissions:nil
                                              allowLoginUI:(controller != nil)
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
    {
        if(handler)
            handler([self isSessionOpen], error);
        
        [self sessionStateChanged:status error:error];
    }];
}


+ (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSParameterAssert(handler);

    if(![self isSessionOpen]) {
        handler(nil, [OKError sessionClosed]);
        return;
    }
    
    FBRequest *fbrequest = [FBRequest requestForMe];
    [fbrequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *err)
     {
         OKAuthRequest *request = nil;
         if (!err && result) {
             
             NSString *token = [[[FBSession activeSession] accessTokenData] accessToken];
             if(token) {
                 NSString *imageUrl = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture", result[@"id"]];
                 request = [[OKAuthRequest alloc] initWithProvider:[self sharedInstance]
                                                            userID:result[@"id"]
                                                          userName:result[@"name"]
                                                      userImageURL:imageUrl
                                                             token:token];
             }
             handler(request, err);
         }
     }];
}


+ (void)logoutAndClear
{
    [[FBSession activeSession] closeAndClearTokenInformation];
}


+ (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler
{
    NSParameterAssert(handler);

    FBRequest *fbrequest = [FBRequest requestForMyFriends];
    [fbrequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *err)
    {
        if(err) {
            handler(nil, err);
        }
        else {
            //NSArray *graphFriends = [result objectForKey:@"data"];
            NSArray *graphFriends = [OKHelper getNSArrayFrom:result key:@"data"];
            if(graphFriends) {
                OKLogInfo(@"Received %d friends", [graphFriends count]);
                NSArray *friendsList = [self makeListOfFacebookFriends:graphFriends];
                handler(friendsList, err);

            } else {
                handler(nil, [OKError unknownFacebookRequestError]);
            }
        }
    }];
}


+ (void)handleErrorLoggingIntoFacebookAndShowAlertIfNecessary:(NSError *)error
{
    NSString *alertMessage, *alertTitle;
    if (!error) {
        alertMessage = nil;
    }
    else if ([FBErrorUtility shouldNotifyUserForError:error]) {
        // If the SDK has a message for the user, surface it. This conveniently
        // handles cases like password change or iOS6 app slider state.
        alertTitle = @"Facebook Error";
        alertMessage = [FBErrorUtility userMessageForError:error];
    } else{
        
        FBErrorCategory code = [FBErrorUtility errorCategoryForError:error];
        switch (code) {
            case FBErrorCategoryAuthenticationReopenSession:
                // It is important to handle session closures since they can happen
                // outside of the app. You can inspect the error for more context
                // but this sample generically notifies the user.
                alertTitle = @"Session Error";
                alertMessage = @"Your current session is no longer valid. Please log in again.";
                break;
                
            case FBErrorCategoryUserCancelled:
                // The user has cancelled a login. You can inspect the error
                // for more context. For this sample, we will simply ignore it.
                NSLog(@"user cancelled login");
                
            default:
                // For simplicity, this sample treats other errors blindly.
                alertTitle  = @"Unknown Error";
                alertMessage = @"Error. Please try again later.";
                NSLog(@"Unexpected FB login error:%@", error);
                break;
        }
    }
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}


+ (NSArray*)makeListOfFacebookFriends:(NSArray*)friendsJSON
{
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[friendsJSON count]];
    
    for(NSDictionary *friendDict in friendsJSON) {
        NSString *friendID = [OKHelper getNSStringFrom:friendDict key:@"id"];
        if(friendID)
            [list addObject:friendID];
    }
    
    return list;
}


+ (void)sessionStateChanged:(FBSessionState)status error:(NSError*)error
{
    switch(status)
    {
        case FBSessionStateOpen:
            OKLogInfo(@"OKFacebookPlugin: Session is open.");
            break;
        case FBSessionStateClosed:
            OKLogInfo(@"OKFacebookPlugin: Session is closed.");
            //break;
        case FBSessionStateClosedLoginFailed:
            OKLogInfo(@"FBSessionStateClosedLoginFailed");
            [FBSession.activeSession closeAndClearTokenInformation];
            
            if([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled)
                OKLogInfo(@"User cancelled FB login");
            break;
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OKAuthProviderUpdatedNotification
                                                        object:self];
}


#pragma mark - Custom API

+ (void)sendFacebookRequest
{
    NSDictionary* params = [NSDictionary dictionary];
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:@"Check out this game!"
                                                    title:@"Invite Friends"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error)
     {
         if (error) {
             // Case A: Error launching the dialog or sending request.
             NSLog(@"Error sending request.");
         } else {
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // Case B: User clicked the "x" icon
                 NSLog(@"User canceled request.");
             } else {
                 NSLog(@"Request Sent.");
             }
         }
     }];
}

@end
