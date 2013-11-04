//
//  OKUtils.m
//  OpenKit
//
//  Created by Louis Zell on 6/16/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKUtils.h"
#import "OKMacros.h"


void OKEncodeObj(id obj, NSString **strOut, NSError **errOut)
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:errOut];
    if (!*errOut) {
        *strOut = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"Json is: %@", *strOut);
    }
}


id OKDecodeObj(NSData *dataIn, NSError **errOut)
{
    NSJSONReadingOptions opts = NSJSONReadingAllowFragments | NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves;
    return [NSJSONSerialization JSONObjectWithData:dataIn options:opts error:errOut];
}


@implementation OKUtils

+ (NSString*)vendorUUID
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (NSString*)createUUID
{
    return [[NSUUID UUID] UUIDString];
}

+ (NSString*)bundleID
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (double)timestamp
{
    return [[NSDate date] timeIntervalSince1970];
}


+ (NSString*)sqlStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    return [dateFormatter stringFromDate:date];
}


+ (NSDate*)dateFromSqlString:(NSString *)string
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneWithName:@"UTC"]];
    return [dateFormatter dateFromString:string];
}


+ (NSString*)base64Enconding:(NSData*)data
{
    if(OK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
        return [data base64EncodedStringWithOptions:0];
    else
        return [data base64Encoding];
}


+ (NSData*)base64Decoding:(NSString*)string
{
    if(OK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
        return [[NSData alloc] initWithBase64EncodedString:string options:0];
    else
        return [[NSData alloc] initWithBase64Encoding:string];
}

@end


@implementation OKMutableInt

- (id)initWithValue:(NSInteger)value;
{
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

@end
