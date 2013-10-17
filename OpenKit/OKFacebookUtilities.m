//
//  OKFacebookUtilities.m
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//


#import <FacebookSDK/FacebookSDK.h>
#import <FacebookSDK/FBErrorUtility.h>
#import "OKFacebookUtilities.h"
#import "OKManager.h"
#import "OKNetworker.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKUser.h"
#import "OKDBScore.h"
#import "OKHelper.h"
#import "AFImageView.h"
#import "OKNotifications.h"
#import "OKPrivate.h"


#define OK_SERVICE_NAME @"facebook"


@implementation OKFacebookPlugin

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}


- (void)handleDidBecomeActive
{
    [FBSession.activeSession handleDidBecomeActive];
}


- (void)handleWillTerminate
{
    [FBSession.activeSession close];
}


+ (OKAuthProvider*)inject
{
    OKAuthProvider *p = [OKAuthProvider providerByName:OK_SERVICE_NAME];
    if(p == nil) {
        p = [[OKFacebookPlugin alloc] init];
        if([p isAuthenticationAvailable])
            [OKAuthProvider addProvider:p];
    }
    
    return p;
}


- (id)init
{
    self = [super initWithName:OK_SERVICE_NAME];
    return self;
}


- (BOOL)isAuthenticationAvailable
{
    return YES;
}


- (BOOL)isSessionOpen
{
    return [[FBSession activeSession] state] == FBSessionStateOpen;
}


- (BOOL)start
{
    return [self openSessionWithViewController:nil completion:nil];
}


- (BOOL)openSessionWithViewController:(UIViewController*)controller completion:(void(^)(NSError *error))handler
{
    if([self isSessionOpen])
        return YES;
    
    return [FBSession openActiveSessionWithReadPermissions:nil
                                              allowLoginUI:(controller != nil)
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error)
    {
        [self sessionStateChanged:status error:error];
        if(handler)
            handler(error);
    }];
}


- (void)getProfileWithCompletion:(void(^)(OKAuthProfile *profile, NSError *error))handler
{
    if(![self isSessionOpen]) {
        handler(nil, [OKError sessionClosed]);
        return;
    }
    
    [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        // Did everything come back okay with no errors?
        if (!error && result) {
            OKAuthProfile *profile = [[OKAuthProfile alloc] initWithProvider:self
                                                                      userID:[result objectForKey:@"id"]
                                                                        name:[result objectForKey:@"name"]];
            // Set url of profile image
            [profile setImageUrl:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture", [result objectForKey:@"id"]]];
            
            handler(profile, nil);
        }
        else {
            //Error performing the FB request
            handler(nil, error);
        }
    }];
}


- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    if(![self isSessionOpen]) {
        handler(nil, [OKError sessionClosed]);
        return;
    }
    [self getProfileWithCompletion:^(OKAuthProfile *profile, NSError *error) {
        
        OKAuthRequest *request = nil;
        NSString *token = [[[FBSession activeSession] accessTokenData] accessToken];
        if(profile && token)
            request = [[OKAuthRequest alloc] initWithProvider:self
                                                       userID:[profile userID]
                                                        token:token];
        
        handler(request, error);
    }];
}


- (void)logoutAndClear
{
    [[FBSession activeSession] closeAndClearTokenInformation];
}


- (void)loadUserImageForUserID:(NSString*)userid completion:(void(^)(UIImage *image, NSError *error))handler
{
    // https://graph.facebook.com/USER_ID/picture
    
}


- (void)loadFriendsWithCompletion:(void(^)(NSArray *friends, NSError *error))handler
{
    [[FBRequest requestForMyFriends] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if(error) {
            handler(nil, error);
        }
        else {
            //NSArray *graphFriends = [result objectForKey:@"data"];
            NSArray *graphFriends = [OKHelper getNSArraySafeForKey:@"data" fromJSONDictionary:result];
            if(graphFriends) {
                OKLog(@"Received %d friends", [graphFriends count]);
                NSArray *friendsList = [self makeListOfFacebookFriends:graphFriends];
                handler(friendsList, error);

            } else {
                handler(nil, [OKError unknownFacebookRequestError]);
            }
        }
    }];
}


- (void)handleErrorLoggingIntoFacebookAndShowAlertIfNecessary:(NSError *)error
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
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        // It is important to handle session closures since they can happen
        // outside of the app. You can inspect the error for more context
        // but this sample generically notifies the user.
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        // The user has cancelled a login. You can inspect the error
        // for more context. For this sample, we will simply ignore it.
        NSLog(@"user cancelled login");
    } else {
        // For simplicity, this sample treats other errors blindly.
        alertTitle  = @"Unknown Error";
        alertMessage = @"Error. Please try again later.";
        NSLog(@"Unexpected FB login error:%@", error);
    }
    
    if (alertMessage) {
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}


- (NSArray*)makeListOfFacebookFriends:(NSArray*) friendsJSON
{
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:[friendsJSON count]];
    
    for(int x = 0; x < [friendsJSON count]; x++)
    {
        NSDictionary *friendDict = [friendsJSON objectAtIndex:x];
        NSString *friendID = [OKHelper getNSStringSafeForKey:@"id" fromJSONDictionary:friendDict];
        if(friendID != nil) {
            [list addObject:friendID];
        }
    }
    
    return list;
}


- (void)sendFacebookRequest
{
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    [FBWebDialogs presentRequestsDialogModallyWithSession:nil
                                                  message:@"Check out this game!"
                                                    title:@"Invite Friends"
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
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
                                                      }}];
}




- (void)sessionStateChanged:(FBSessionState)status error:(NSError*)error
{
    switch(status)
    {
        case FBSessionStateOpen:
            OKLogInfo(@"FBSessionStateOpen");
            break;
        case FBSessionStateClosed:
            OKLogInfo(@"FBSessionStateClosed");
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
    [[NSNotificationCenter defaultCenter] postNotificationName:OKAuthProviderUpdatedNotification object:self];
}

@end
