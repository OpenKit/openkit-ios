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

+(NSError*)noOKUserError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:2 userInfo:[NSDictionary dictionaryWithObject:@"No valid OKUser passed in" forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)unknownError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:3 userInfo:[NSDictionary dictionaryWithObject:@"Unknown OpenKit error" forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)noGameCenterIDError {
     return [NSError errorWithDomain:OKERROR_DOMAIN code:4 userInfo:[NSDictionary dictionaryWithObject:@"No game center ID for this leaderboard so can't get scores from GameCenter" forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)unknownGameCenterError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:5 userInfo:[NSDictionary dictionaryWithObject:@"Unknown error from GameCenter" forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)unknownFacebookRequestError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:6 userInfo:[NSDictionary dictionaryWithObject:@"Unknown error from Facebook" forKey:NSLocalizedDescriptionKey]];
}

+(NSError*)gameCenterNotAvailableError {
        return [NSError errorWithDomain:OKERROR_DOMAIN code:7 userInfo:[NSDictionary dictionaryWithObject:@"GameCenter is not available (player may not be authenticated in)" forKey:NSLocalizedDescriptionKey]];
}





@end
