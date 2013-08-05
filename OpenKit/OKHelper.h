//
//  OKHelper.h
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKHelper : NSObject

+ (NSDate *)dateNDaysFromToday:(int)n;
+(NSString*)getStringSafeForKey:(NSString*)key fromJSONDictionary:(NSDictionary*)jsonDict;

@end
