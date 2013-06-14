//
//  OKGKScoreWrapper.h
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface OKGKScoreWrapper : NSObject

@property (nonatomic, strong) GKScore *score;
@property (nonatomic, strong) GKPlayer *player;

@end
