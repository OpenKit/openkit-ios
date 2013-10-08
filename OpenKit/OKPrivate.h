//
//  OKPrivate.h
//  OKClient
//
//  Created by Manu Mtz-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//


@interface OKLeaderboard (Private)

- (void)submitScore:(OKScore*)score withCompletion:(void (^)(NSError* error))handler;

@end

