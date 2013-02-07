//
//  OKCloud.h
//  OKClient
//
//  Created by Louis Zell on 1/23/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OKCloud : NSObject

+ (void)set:(id)obj key:(NSString *)key completion:(void (^)(id obj, NSError *err))completion;
+ (void)get:(NSString *)key completion:(void (^)(id obj, NSError *err))completion;

@end
