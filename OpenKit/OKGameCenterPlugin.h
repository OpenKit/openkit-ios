//
//  OKGameCenterPlugin.h
//  Openkit
//
//  Created by Suneet Shah and Manu Mtz-Almeida.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#define OKGameCenterPluginAuthStateNotification @"OKGameCenterPluginAuthStateNotification"


@interface OKGameCenterPlugin : NSObject

//! Returns if GameCenter is available in this devices.
+ (BOOL)isGCAvailable;

//! Returns if the user is authenticated in GameCenter.
+ (BOOL)isPlayerAuthenticated;

//! Start up the plugin and authorize the user in GC.
+ (void)authorizeUserWithViewController:(UIViewController*)controller completion:(void(^)(NSError* error))handler;

//! Gets an array of GKPlayer (instances of gamecenter users) given a the list of IDs.
+ (void)loadPlayersWithIDs:(NSArray*)playerIDs completion:(void(^)(NSArray *friends, NSError *error))handler;

//! Gets an array of IDs of your GameCenter friends.
+ (void)loadFriendIDsWithCompletion:(void(^)(NSArray *friendIDs, NSError *error))handler;


+ (void)loadFriendsWithCompletion:(void(^)(NSArray *friendIDs, NSError *error))handler;

+ (void)loadPlayerPhotoWithID:(NSString*)gameCenterID
                    photoSize:(GKPhotoSize)photoSize
                   completion:(void(^)(UIImage *photo, NSError *error))handler;

+ (void)logout;

@end