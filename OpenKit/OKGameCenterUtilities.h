//
//  OKGameCenterUtilities.h
//  OpenKit
//
//  Created by Suneet Shah on 6/12/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface OKGameCenterUtilities : NSObject

+(void)loadPlayerPhotoForGameCenterID:(NSString*)gameCenterID withPhotoSize:(GKPhotoSize)photoSize withCompletionHandler:(void(^)(UIImage *photo, NSError *error))completionhandler;
+(BOOL)gameCenterIsAvailable;
+(void)authenticateLocalPlayer;
+(void)authorizeUserWithGameCenterAndallowUI:(BOOL)allowUI withPresentingViewController:(UIViewController*)presenter;

@end
