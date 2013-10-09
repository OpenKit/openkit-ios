//
//  OKUser.m
//  OKClient
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "OKUser.h"
#import "OKManager.h"


@implementation OKUser

- (id)init
{
    return [self initWithUserID:nil withUserNick:nil withFBID:nil withCustomID:nil];
}


- (id)initWithUserID:(NSNumber *)userID withUserNick:(NSString *)nick withFBID:(NSString *)fbID withCustomID:(NSString*)customID
{
    self = [super init];
    if (self) {
        _OKUserID = userID;
        _userNick = nick;
        _fbUserID = fbID;
        _customID = customID;
        //self.twitterUserID = _twitterID;
        //self.gameCenterID = _gameCenterID;
    }
    
    return self;
}


+ (OKUser*)currentUser
{
    return [[OKManager sharedManager] currentUser];
}


+ (void)logoutCurrentUserFromOpenKit
{
    [[OKManager sharedManager] logoutCurrentUser];
}

@end
