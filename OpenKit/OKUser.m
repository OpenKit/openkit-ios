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

@synthesize OKUserID, userNick, fbUserID, twitterUserID, gameCenterID, customID;

- (id)init
{
    return [self initWithUserID:nil withUserNick:nil withFBID:nil withTwitterId:nil withGameCenterID:nil withCustomID:nil];
}

//Designated initializer
- (id)initWithUserID:(NSNumber *)_OKUserID withUserNick:(NSString *)_userNick withFBID:(NSNumber *)_fbID withTwitterId:(NSNumber *)_twitterID withGameCenterID:(NSString*)_gameCenterID withCustomID:(NSNumber*)_customID
{
    self = [super init];
    if (self) {
        self.OKUserID = _OKUserID;
        self.userNick = _userNick;
        self.fbUserID = _fbID;
        self.twitterUserID = _twitterID;
        self.gameCenterID = _gameCenterID;
        self.customID = _customID;
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
