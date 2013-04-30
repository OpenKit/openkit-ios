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

#define USE_JSONKIT  1


#import "OKCloud.h"
#import "OKUser.h"
#import "OKCloudAsyncRequest.h"
#import "JSONKit.h"
#import "OKMacros.h"
#import "OKError.h"

static void
encodeObj(id obj, NSString **strOut, NSError **errOut)
{
#if USE_JSONKIT
    JKSerializeOptionFlags opts = JKSerializeOptionNone;
    if ([obj isKindOfClass:[NSString class]]) {
        *strOut = [obj JSONStringWithOptions:opts includeQuotes:YES error:errOut];
    }
    else {
        *strOut = [obj JSONStringWithOptions:opts error:errOut];
    }
    NSLog(@"Json is: %@", *strOut);
#else
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NULL error:errOut];
    if (!*errOut) {
        *strOut = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"Json is: %@", *strOut);
    }
#endif
}

static id
decodeObj(NSData *dataIn, NSError **errOut)
{
#if USE_JSONKIT
    JSONDecoder *decoder = [JSONDecoder decoderWithParseOptions:JKParseOptionNone];
    id obj = [decoder objectWithData:dataIn error:errOut];
    return obj;
#else
    NSJSONReadingOptions opts = NSJSONReadingAllowFragments | NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves;
    return [NSJSONSerialization JSONObjectWithData:dataIn options:opts error:errOut];
#endif
}


@implementation OKCloud


+ (void)set:(id)obj key:(NSString *)key completion:(void (^)(id obj, NSError *err))completion
{
    OKUser *user = [OKUser currentUser];
    
    if(user == nil) {
        completion(nil, [OKError userNotLoggedInError]);
        return;
    }
    
    NSError *err;
    NSString *objRep;

    encodeObj(obj, &objRep, &err);

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            user.OKUserID,  @"user_id",
                            key,            @"field_key",
                            objRep,         @"field_value",
                            nil];

    OKCloudAsyncRequest *req = [[OKCloudAsyncRequest alloc] initWithPath:@"/developer_data"
                                                 requestMethod:@"POST"
                                                    parameters:params];

    [req performWithCompletionHandler:^(id responseObj, NSError *err) {
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
    OKCloudAsyncRequest *req = [[OKCloudAsyncRequest alloc] initWithPath:path
                                                 requestMethod:@"GET"
                                                    parameters:params];

    [req performWithCompletionHandler:^(id responseObj, NSError *err) {
#ifdef DEBUG
        OKLog(@"OKCloud Response: %@", [[NSString alloc] initWithData:responseObj encoding:NSUTF8StringEncoding]);
#endif
        id o = nil;
        if (!err) {
            NSDictionary *dict = decodeObj(responseObj, &err);
            if (!err) {
                o = [dict objectForKey:key];
                if ([o isKindOfClass:[NSNull class]]) {
                    o = nil;
                }
            }
        }
        completion(o, err);
    }];
}

@end
