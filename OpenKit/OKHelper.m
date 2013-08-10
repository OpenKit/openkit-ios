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

+(NSString*)getStringSafeForKey:(NSString*)key fromJSONDictionary:(NSDictionary*)jsonDict
{
    NSString *value = [jsonDict objectForKey:key];
    
    if([OKHelper isEmpty:value]) {
        return nil;
    } else {
        return value;
    }
}

+(NSString*)getPathToDocsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}



@end
