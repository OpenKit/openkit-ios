//
//  OKGKScoreWrapper.m
//  OpenKit
//
//  Created by Suneet Shah on 6/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKGKScoreWrapper.h"

@implementation OKGKScoreWrapper

@synthesize score, player;

/** OKScoreProtocol Implementation **/
-(NSString*)scoreDisplayString {
    return [[self score] formattedValue];
}
-(NSString*)userDisplayString {
    return [[self player] displayName];
}

-(NSString*)rankDisplayString {
    return [NSString stringWithFormat:@"%d",[[self score] rank]];
}

-(int64_t)scoreValue {
    return [[self score] value];
}


@end
