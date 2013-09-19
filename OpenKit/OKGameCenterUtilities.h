//
//  OKGameCenterUtilities.h
//  OpenKit
//
//  Created by Suneet Shah on 6/12/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

typedef void(^OKGameCenterLoginCompletionHandler)(NSError *error);

@interface OKGameCenterUtilities : NSObject

+(void)loadPlayerPhotoForGameCenterID:(NSString*)gameCenterID withPhotoSize:(GKPhotoSize)photoSize withCompletionHandler:(void(^)(UIImage *photo, NSError *error))completionhandler;
+(BOOL)isPlayerAuthenticatedWithGameCenter;
+(BOOL)isGameCenterAvailable;

+(BOOL)shouldUseLegacyGameCenterAuth;
+(void)authenticateLocalPlayerLegacyWithCompletionHandler:(OKGameCenterLoginCompletionHandler)completionHandler;
+(void)authenticateLocalPlayerWithCompletionHandler:(OKGameCenterLoginCompletionHandler)completionHandler showUI:(BOOL)showUI presentingViewController:(UIViewController*)presenter;


@end
