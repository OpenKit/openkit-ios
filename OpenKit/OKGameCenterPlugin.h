//
//  OKGameCenterPlugin.h
//  Openkit
//
//  Created by Suneet Shah and Manu Mtz-Almeida.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "OKAuth.h"


@interface OKGameCenterPlugin : OKAuthProvider

//! Gets an array of GKPlayer (instances of gamecenter users) given a the list of IDs.
+ (void)loadPlayersWithIDs:(NSArray*)playerIDs completion:(void(^)(NSArray *friends, NSError *error))handler;

@end
