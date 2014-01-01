//
//  OKGame.h
//  OKClient
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKDBConnection.h"
#import "OKLeaderboard.h"
#import "OKUser.h"
#import "OKDefines.h"
#import "OKDBConnection.h"

typedef void (^OKReplayBlock)(double progress, double step, id data);


@interface OKReplay : NSObject
@property(nonatomic, readwrite) double speed;
@property(nonatomic, strong) OKReplayBlock replayHandler;
@property(nonatomic, strong) OKBlock completionHandler;

- (void)replayWithBlock:(OKReplayBlock)block completion:(OKBlock)handler;
- (void)setProgress:(double)progress;
- (void)start;
- (void)stop;
- (void)step;

@end


@interface OKGame : OKDBRow
@property(nonatomic, readonly) NSUInteger gameID;
@property(nonatomic, readonly) NSDictionary *contextData;

- (id)initWithDictionary:(NSDictionary*)dict;
- (void)catchInstant:(id)obj;
- (double)playingTime;
- (OKReplay*)replay;
- (NSDictionary*)archive;
- (void)replayWithBlock:(OKReplayBlock)block;


@end
