//
//  OKTwitterUtilities.h
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenKit.h"
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>


@interface OKTwitterUtilities : NSObject

+(void)AuthorizeTwitterAccount:(ACAccount *)twitterAccount withCompletionHandler:(void(^)(OKUser *newUser, NSError *error))completionHandler;
+(void)GetProfileImageURLFromTwitterUserID:(NSString *)twitterID;

@end
