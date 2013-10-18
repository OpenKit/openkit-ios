//
//  OKHelper.m
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKHelper.h"
#import "OKUtils.h"


@implementation OKHelper

+ (NSDate *)dateNDaysFromToday:(int)n
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = n;
    return [calendar dateByAddingComponents:components toDate:now options:0];
}


+ (BOOL)isEmpty:(id)obj
{
    return obj == nil ||
    ([obj respondsToSelector:@selector(length)] && [(NSData *)obj length] == 0) ||
    ([obj respondsToSelector:@selector(count)] && [(NSArray *)obj count] == 0) ||
    (obj == [NSNull null]);
}


+ (NSArray*)getNSArrayFrom:(NSDictionary*)dict key:(NSString *)key;
{
    if(![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    id value = [dict objectForKey:key];
    
    if([value isKindOfClass:[NSArray class]]) {
        return value;
    } else {
        return nil;
    }
}


+ (BOOL)getBOOLFrom:(NSDictionary*)dict key:(NSString *)key;
{
    NSNumber *numberValue = [OKHelper getNSNumberFrom:dict key:key];
    
    if(numberValue != nil) {
        return [numberValue boolValue];
    } else {
        return NO;
    }
}


+ (int64_t)getInt64From:(NSDictionary*)dict key:(NSString *)key;
{
    NSNumber *numberValue = [OKHelper getNSNumberFrom:dict key:key];
    if(numberValue) {
        return [numberValue longLongValue];
    } else {
        return 0;
    }
}


+ (int)getIntFrom:(NSDictionary*)dict key:(NSString *)key;
{
    NSNumber *numberValue = [OKHelper getNSNumberFrom:dict key:key];
    if(numberValue) {
        return [numberValue integerValue];
    } else {
        return 0;
    }
}


+ (NSNumber*)getNSNumberFrom:(NSDictionary*)dict key:(NSString *)key;
{
    if(![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    id value = [dict objectForKey:key];
    
    if([value isKindOfClass:[NSNumber class]]) {
        return value;
    } else if ([value isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString*)value;
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *number = [formatter numberFromString:stringValue];
        return number;
    } else {
        return nil;
    }
}


+ (NSDate*)getNSDateFrom:(NSDictionary*)dict key:(NSString *)key;
{
    if(![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    id value = [dict objectForKey:key];
    
    if([value isKindOfClass:[NSDate class]]) {
        return value;
    } else if([value isKindOfClass:[NSString class]]) {
        return [OKUtils dateFromSqlString:value];
    }else{
        return nil;
    }
}


+ (NSString*)getNSStringFrom:(NSDictionary*)dict key:(NSString *)key;
{
    if(![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSString *value = [dict objectForKey:key];
    
    if([value isKindOfClass:[NSString class]]) {
        if([OKHelper isEmpty:value]) {
            return nil;
        } else {
            return value;
        }
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *numberValue = (NSNumber*)value;
        return [numberValue stringValue];
    } else {
        return  nil;
    }
}


+ (NSDictionary*)getNSDictionaryFrom:(NSDictionary*)dict key:(NSString *)key;
{
    if(![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *value = [dict objectForKey:key];
    
    if([value isKindOfClass:[NSDictionary class]]) {
        return value;
    } else {
        return nil;
    }
}


+ (NSString*)getPathToDocsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}


+ (NSString*)serializeArray:(NSArray*)array withSorting:(BOOL)sorting
{
    if(sorting)
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSMutableString *result = [[NSMutableString alloc] init];
    
    for(NSString *string in array) {
        [result appendString:string];
        [result appendString:@","];
    }
    int size = [result length];
    [result deleteCharactersInRange:NSMakeRange(size-1, 1)];
    return result;
}

@end
