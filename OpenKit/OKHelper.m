//
//  OKHelper.m
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKHelper.h"

@implementation OKHelper

+ (NSDate *)dateNDaysFromToday:(int)n
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = n;
    return [calendar dateByAddingComponents:components toDate:now options:0];
}

+(BOOL)isEmpty:(id)obj
{
    return obj == nil ||
    ([obj respondsToSelector:@selector(length)] && [(NSData *)obj length] == 0) ||
    ([obj respondsToSelector:@selector(count)] && [(NSArray *)obj count] == 0) ||
    (obj == [NSNull null]);
}

+(NSArray*)getNSArraySafeForKey:(NSString*)key fromJSONDictionary:(NSDictionary*)jsonDict
{
    if(![jsonDict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    id value = [jsonDict objectForKey:key];
    
    if([value isKindOfClass:[NSArray class]]) {
        return value;
    } else {
        return nil;
    }
}

+(NSNumber*)getNSNumberSafeForKey:(NSString*)key fromJSONDictionary:(NSDictionary*)jsonDict
{
    if(![jsonDict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    id value = [jsonDict objectForKey:key];
    
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

+(NSString*)getStringSafeForKey:(NSString*)key fromJSONDictionary:(NSDictionary*)jsonDict
{
    if(![jsonDict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSString *value = [jsonDict objectForKey:key];
    
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

+(NSString*)getPathToDocsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}



@end
