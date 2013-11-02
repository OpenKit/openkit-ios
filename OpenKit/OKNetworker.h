//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKResponse.h"

#define OK_UNSUBSCRIBED_USER_ERROR_CODE 410

@interface OKNetworker : NSObject

+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
         completion:(void (^)(OKResponse *response))handler;

+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
        completion:(void (^)(OKResponse *response))handler;

+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
       completion:(void (^)(OKResponse *response))handler;

@end
