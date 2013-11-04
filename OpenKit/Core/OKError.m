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

+ (NSError*)userNotLoggedInError
{
    return [NSError errorWithDomain:OKERROR_DOMAIN code:USER_NOT_LOGGED_IN_CODE userInfo:@{NSLocalizedDescriptionKey: @"OpenKit User is not logged in"}];
}

+ (NSError*)noOKUserError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:2 userInfo:@{NSLocalizedDescriptionKey: @"No valid OKUser passed in"}];
}

+ (NSError*)noOKUserErrorScoreCached {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:10 userInfo:@{NSLocalizedDescriptionKey: @"The score was not submitted to OpenKit because the user is not logged in, but it is cached locally on the device and will be submitted to OpenKit when the user logs in."}];
}

+ (NSError*)unknownError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:3 userInfo:@{NSLocalizedDescriptionKey: @"Unknown OpenKit error"}];
}

+ (NSError*)noGameCenterIDError {
     return [NSError errorWithDomain:OKERROR_DOMAIN code:4 userInfo:@{NSLocalizedDescriptionKey: @"No game center ID for this leaderboard so can't get scores from GameCenter"}];
}

+ (NSError*)unknownGameCenterError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:5 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error from GameCenter"}];
}

+ (NSError*)unknownFacebookRequestError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:6 userInfo:@{NSLocalizedDescriptionKey: @"Unknown error from Facebook"}];
}

+ (NSError*)gameCenterNotAvailableError {
        return [NSError errorWithDomain:OKERROR_DOMAIN code:7 userInfo:@{NSLocalizedDescriptionKey: @"GameCenter is not available (player may not be authenticated in)"}];
}

+ (NSError*)OKServerRespondedWithDifferentUserIDError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:8 userInfo:@{NSLocalizedDescriptionKey: @"The OpenKit server responded with a different OKUser id than expected"}];
}

+ (NSError*)OKScoreNotSubmittedError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:9 userInfo:@{NSLocalizedDescriptionKey: @"The score was not submitted to the OpenKit server because it is not better than previous submitted score. It may have still been submitted to GameCenter."}];
}

+ (NSError*)noBodyError {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:11 userInfo:@{NSLocalizedDescriptionKey: @"No body error"}];
}

+ (NSError*)sessionClosed {
    return [NSError errorWithDomain:OKERROR_DOMAIN code:12 userInfo:@{NSLocalizedDescriptionKey: @"The session in the auth service is not open."}];
}

@end
