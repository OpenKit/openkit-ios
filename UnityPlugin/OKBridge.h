//
//  OKBridge.h
//  OKBridge
//
//  Updated by Lou Zell on 2/14/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
//  Email feedback and suggestions to Lou at lzell11@gmail.com
//

#import <Foundation/Foundation.h>

#pragma mark - Configuration

void OKBridgeConfigureOpenKit(const char *appKey, const char *secretKey);
void OKBridgeConfigureOpenKitWithHost(const char *appKey, const char *secretKey, const char *endpoint);
void OKBridgeSetLeaderboardListTag(const char *tag);


#pragma mark - Session management

bool OKBridgeIsUserAuthenticated();
int OKBridgeGetUserID();
const char* OKBridgeGetUserNick();
const char* OKBridgeGetUserFBID();
bool OKBridgeIsUserAuthenticatedWithService(const char *serviceName);
bool OKBridgeIsUserAuthenticatedWithGameCenter();
void OKBridgeLogoutUser();
void OKBridgeAuthenticateUserWithService(const char *serviceName);
void OKBridgeAuthenticateUserWithGamecenter();
void OKBridgeAuthenticateUserWithFacebook();


#pragma mark - Scores

void OKBridgeSubmitScore(int64_t scoreValue, int leaderboardID, int metadata, const char *displayString, const char *gameObjectName );


#pragma mark - UI

void OKBridgeShowLeaderboardsList();
void OKBridgeShowLeaderboardID(int leaderboardID);
void OKBridgeGetFacebookFriends(const char *gameObject);
void OKBridgeShowLoginUI();
void OKBridgeShowLoginUIWithBlock(const char *gameObject);
