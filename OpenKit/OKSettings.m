//
//  OKSettings.m
//  OpenKit
//
//  Created by Suneet Shah on 10/21/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSettings.h"
#import "OKNetworker.h"
#import "OKMacros.h"
#import "OKHelper.h"

#define OK_CHAT_KEY @"chat"

@implementation OKSettings

-(id)init
{
    self = [super init];
    if(self) {
        [self getRemoteSettings];
    }
    return self;
}

-(void)getRemoteSettings
{
    [OKNetworker getFromPath:@"/features" parameters:nil handler:^(id responseObject, NSError *error) {
        OKLog(@"Got response from settings: %@", responseObject);
        
        
        BOOL chatFeature = [OKHelper getBOOLSafeForKey:@"chat" fromJSONDictionary:responseObject];
        
        
    }];
}

-(BOOL)isChatEnabled
{
    // returns NO if no key is found
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:OK_CHAT_KEY];
}


@end
