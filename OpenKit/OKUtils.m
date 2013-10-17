//
//  OKUtils.m
//  OpenKit
//
//  Created by Louis Zell on 6/16/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKUtils.h"


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

+ (NSString*)createUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}


+ (NSString*)sqlStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat: @"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneWithName:@"UTC"]];
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
    return [data base64EncodedStringWithOptions:0];
}

+ (NSData*)base64Decoding:(NSString*)string
{
    return [[NSData alloc] initWithBase64EncodedString:string options:0];
}

@end


@implementation OKMutableInt

- (id)initWithValue:(int)value;
{
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

@end
