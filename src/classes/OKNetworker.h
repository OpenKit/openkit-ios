//
//  OKScore.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPClient;
@interface OKNetworker : NSObject

+ (AFHTTPClient*) httpClient;

+ (void) requestWithMethod:(NSString*)method
                      path:(NSString*)path
                parameters:(NSDictionary*)params
                   handler:(void (^)(id responseObject, NSError* error))handler;

+ (void) getFromPath:(NSString*)path
          parameters:(NSDictionary*)params
             handler:(void (^)(id responseObject, NSError* error))handler;

+ (void) postToPath:(NSString*)path
         parameters:(NSDictionary*)params
            handler:(void (^)(id responseObject, NSError* error))handler;

+ (void) putToPath:(NSString*)path
        parameters:(NSDictionary*)params
           handler:(void (^)(id responseObject, NSError* error))handler;

@end
