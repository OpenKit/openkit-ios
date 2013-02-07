//
//  OKFacebookUtilities.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OKUser;
@interface OKFacebookUtilities : NSObject

+(BOOL)handleOpenURL:(NSURL *)url;
+(void)handleDidBecomeActive;
+(void)handleWillTerminate;

+(void)AuthorizeUserWithFacebookWithCompletionHandler:(void(^)(OKUser *user, NSError *error))completionHandler;
+(BOOL)OpenCachedFBSessionWithoutLoginUI;

@end
