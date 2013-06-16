//
//  OKCloud.m
//  OKClient
//
//  Created by Louis Zell on 1/23/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
// Ruby:
// x = {"aKey"=>{"foo"=>"bar"}}
// x.to_json  #=> "{\"aKey\":{\"foo\":\"bar\"}}"
//
// GDB:
// po [[(NSDictionary *)[decoder objectWithUTF8String:"{\"aKey\":{\"foo\":\"bar\"}}" length:22] objectForKey:@"aKey"] class]  #=> JKDictionary
//
// Redis cli:
// hget "dev:1:user:11" "firstKey"


#import "OKCloud.h"
#import "OKUser.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKUtils.h"
#import "OKNetworker.h"


@implementation OKCloud


+ (void)set:(id)obj key:(NSString *)key completion:(void (^)(id obj, NSError *err))completion
{
    OKUser *user = [OKUser currentUser];

    if(user == nil) {
        completion(nil, [OKError userNotLoggedInError]);
        return;
    }
    
    // AFNetworking will handle encode of 'obj'...
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            user.OKUserID,  @"user_id",
                            key,            @"field_key",
                            obj,            @"field_value",
                            nil];

    [OKNetworker postToPath:@"/developer_data" parameters:params handler:^(id responseObj, NSError *err) {
        completion(obj, err);
    }];
}


+ (void)get:(NSString *)key completion:(void (^)(id obj, NSError *err))completion
{
    OKUser *user = [OKUser currentUser];
    
    if(user == nil) {
        completion(nil, [OKError userNotLoggedInError]);
        return;
    }
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            user.OKUserID,  @"user_id",
                            nil];

    NSString *path = [NSString stringWithFormat:@"/developer_data/%@", key];
    [OKNetworker getFromPath:path parameters:params handler:^(id responseDict, NSError *err) {
        id o = nil;
        if (!err) {
            o = [responseDict objectForKey:key];
            if ([o isKindOfClass:[NSNull class]]) {
                o = nil;
            }
        }
        completion(o, err);
    }];
}

@end
