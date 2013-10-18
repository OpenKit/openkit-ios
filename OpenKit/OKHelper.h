//
//  OKHelper.h
//  OKClient
//
//  Created by Suneet Shah on 1/7/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKHelper : NSObject

+ (NSDate*)dateNDaysFromToday:(int)n;
+ (int)getIntFrom:(NSDictionary*)dict key:(NSString *)key;
+ (int64_t)getInt64From:(NSDictionary*)dict key:(NSString *)key;
+ (BOOL)getBOOLFrom:(NSDictionary*)dict key:(NSString *)key;
+ (NSArray*)getNSArrayFrom:(NSDictionary*)dict key:(NSString *)key;
+ (NSString*)getNSStringFrom:(NSDictionary*)dict key:(NSString *)key;
+ (NSNumber*)getNSNumberFrom:(NSDictionary*)dict key:(NSString *)key;
+ (NSDate*)getNSDateFrom:(NSDictionary*)dict key:(NSString *)key;
+ (NSDictionary*)getNSDictionaryFrom:(NSDictionary*)dict key:(NSString *)key;
+ (NSString*)getPathToDocsDirectory;
+ (BOOL)isEmpty:(id)obj;
+ (NSString*)serializeArray:(NSArray*)array withSorting:(BOOL)sorting;

@end
