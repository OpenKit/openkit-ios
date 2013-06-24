//
//  OKUtils.m
//  OpenKit
//
//  Created by Louis Zell on 6/16/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKUtils.h"

#define USE_JSONKIT  1
#if USE_JSONKIT
#import "JSONKit.h"
#endif

void OKEncodeObj(id obj, NSString **strOut, NSError **errOut)
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

id OKDecodeObj(NSData *dataIn, NSError **errOut)
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

