//
//  OKUtils.h
//  OpenKit
//
//  Created by Louis Zell on 6/16/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

void OKEncodeObj(id obj, NSString **strOut, NSError **errOut);
id OKDecodeObj(NSData *dataIn, NSError **errOut);

@interface OKUtils : NSObject

+ (NSString*)createUUID;
+ (NSUInteger)timestamp;
+ (NSString*)sqlStringFromDate:(NSDate *)date;
+ (NSDate*)dateFromSqlString:(NSString *)string;
+ (NSString*)base64Enconding:(NSData*)data;
+ (NSData*)base64Decoding:(NSString*)string;

@end

@interface OKMutableInt : NSObject
@property(atomic, readwrite) NSInteger value;
- (id)initWithValue:(NSInteger)value;
@end

