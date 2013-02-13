//
//  OKTwitterUtilities.h
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Foundation/Foundation.h>

@class OKUser;
@interface OKTwitterUtilities : NSObject

+(void)AuthorizeTwitterAccount:(ACAccount *)twitterAccount withCompletionHandler:(void(^)(OKUser *newUser, NSError *error))completionHandler;
+(void)GetProfileImageURLFromTwitterUserID:(NSString *)twitterID;

@end
