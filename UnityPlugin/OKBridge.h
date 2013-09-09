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

/* Settings methods*/
void OKBridgeSetAppKey(const char *appKey);
void OKBridgeSetSecretKey(const char *secretKey);
void OKBridgeSetEndpoint(const char *endpoint);
void OKBridgeSetLeaderboardListTag(const char *tag);

/* Show leaderboards and UI methods */
void OKBridgeShowLeaderboards();
void OKBridgeShowLeaderboardsLandscapeOnly();
void OKBridgeShowLeaderboardIDWithLandscapeOnly(int leaderboardID, BOOL landscapeOnly);
void OKBridgeShowLeaderboardID(int leaderboardID);
void OKBridgeShowLoginUI();

void OKBridgeSubmitScore(int64_t scoreValue, int leaderboardID, int metadata, const char *displayString, const char *gameObjectName);

/* GameCenter Methods */
void OKBridgeAuthenticateLocalPlayerWithGameCenter();
bool OKBridgeIsPlayerAuthenticatedWithGameCenter();
void OKBridgeAuthenticateLocalPlayerWithGameCenterAndShowUIIfNecessary();

/*OKUser methods*/
int OKBridgeGetCurrentUserOKID();
const char* OKBridgeGetCurrentUserNick();
long long OKBridgeGetCurrentUserFBID();
long long OKBridgeGetCurrentUserTwitterID();
void OKBridgeLogoutCurrentUserFromOpenKit();

void OKBridgeGetFacebookFriends(const char *gameObjectName);

