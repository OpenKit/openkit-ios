//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define OK_UNSUBSCRIBED_USER_ERROR_CODE 410


enum
{
    kOKNetworkerRequest_other = -1,
    kOKNetworkerRequest_getLeaderboards = 1,    
};

@interface OKNetworker : NSObject

+ (NSInteger)getStatusCodeFromAFNetworkingError:(NSError*)error;

+ (void)performWithMethod:(NSString *)method
                     path:(NSString *)path
               parameters:(NSDictionary *)params
               completion:(void (^)(id responseObject, NSError *error))handler;

+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
         completion:(void (^)(id responseObject, NSError *error))handler;

+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
        completion:(void (^)(id responseObject, NSError *error))handler;

+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
       completion:(void (^)(id responseObject, NSError *error))handler;


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
                tag:(NSInteger)tag
         completion:(void (^)(id responseObject, NSError *error))handler;

+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
               tag:(NSInteger)tag
        completion:(void (^)(id responseObject, NSError *error))handler;

+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
              tag:(NSInteger)tag
       completion:(void (^)(id responseObject, NSError *error))handler;

@end
