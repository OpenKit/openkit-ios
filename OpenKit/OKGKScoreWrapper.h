//
//  OKGKScoreWrapper.h
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "OKScoreProtocol.h"

@interface OKGKScoreWrapper : NSObject<OKScoreProtocol>

@property (nonatomic, strong) GKScore *score;
@property (nonatomic, strong) GKPlayer *player;

@end
