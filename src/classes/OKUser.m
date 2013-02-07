//
//  OKUser.m
//  OKClient
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKUser.h"
#import <FacebookSDK/FacebookSDK.h>
#import "OpenKit.h"

@implementation OKUser

@synthesize OKUserID, userNick, fbUserID, twitterUserID;

- (id)init
{
    return [self initWithUserID:nil withUserNick:nil withFBID:nil withTwitterId:nil];
}

//Designated initializer
- (id)initWithUserID:(NSNumber *)_OKUserID withUserNick:(NSString *)_userNick withFBID:(NSNumber *)_fbID withTwitterId:(NSNumber *)_twitterID
{
    self = [super init];
    if (self) {
        self.OKUserID = _OKUserID;
        self.userNick = _userNick;
        self.fbUserID = _fbID;
        self.twitterUserID = _twitterID;
    }
    
    return self;
}

+ (OKUser*)currentUser
{
    return [[OpenKit sharedInstance] currentUser];
}

+ (void)logoutCurrentUserFromOpenKit
{
    [[OpenKit sharedInstance] logoutCurrentUser];
}

@end
