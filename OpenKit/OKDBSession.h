//
//  OKSessionDb.h
//  OpenKit
//
//  Created by Louis Zell on 8/22/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
//
#import <Foundation/Foundation.h>

#import "OKLocalCache.h"
#import "OKSession.h"


@interface OKDBSession : OKDBConnection

- (OKSession*)lastSession;

@end

