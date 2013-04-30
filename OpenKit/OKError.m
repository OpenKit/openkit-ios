//
//  OKError.m
//  OpenKit
//
//  Created by Suneet Shah on 4/24/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKError.h"
#define OKERROR_DOMAIN @"OpenKit"

#define USER_NOT_LOGGED_IN_CODE 1

@implementation OKError

+(NSError*)userNotLoggedInError
{
    return [NSError errorWithDomain:OKERROR_DOMAIN code:USER_NOT_LOGGED_IN_CODE userInfo:[NSDictionary dictionaryWithObject:@"User is not logged in" forKey:@"description"]];
}

@end
