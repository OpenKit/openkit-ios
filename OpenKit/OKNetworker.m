//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "AFNetworking.h"
#import "OKNetworker.h"
#import "OKManager.h"
#import "OKUtils.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKPrivate.h"


typedef void (^OKNetworkerBlock)(id responseObject, NSError * error);


static AFHTTPRequestOperationManager *__httpManager = nil;
static NSString *OK_SERVER_API_VERSION = @"v2";


@implementation OKNetworker

+ (AFHTTPRequestOperationManager*)httpManager
{
    if(!__httpManager) {
        NSURL *baseEndpointURL = [NSURL URLWithString:[OKManager endpoint]];
        NSURL *endpointUrl = [NSURL URLWithString:OK_SERVER_API_VERSION relativeToURL:baseEndpointURL];  
        
        
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        
        AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
        
        __httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:endpointUrl];
        [(AFJSONResponseSerializer*)[__httpManager responseSerializer] setReadingOptions:NSJSONReadingAllowFragments];
        [__httpManager setSecurityPolicy:policy];
        [__httpManager setRequestSerializer:serializer];
    }
    return __httpManager;
}


+ (NSInteger)getStatusCodeFromAFNetworkingError:(NSError*)error
{
    return [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
}


+ (NSMutableURLRequest*)requestWithMethod:(NSString*)method
                                     path:(NSString*)path
                               parameters:(NSDictionary*)params
{
    AFHTTPRequestOperationManager *httpManager = [self httpManager];
    NSString *absolutePath = [[NSURL URLWithString:path relativeToURL:[httpManager baseURL]] absoluteString];
    NSMutableURLRequest *request = [[[self httpManager] requestSerializer] requestWithMethod:method
                                                                                   URLString:absolutePath
                                                                                  parameters:params];    
    return request;
}


+ (void)performWithMethod:(NSString *)method
                     path:(NSString *)path
               parameters:(NSDictionary *)params
               completion:(void (^)(id responseObject, NSError * error))handler
{    
    // SUCCESS BLOCK
    void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *op, id response)
    {
        NSError *err;
        id decodedObj = OKDecodeObj(response, &err);
        if(handler)
            handler(decodedObj, err);
    };

    
    // FAILURE BLOCK
    void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^(AFHTTPRequestOperation *op, NSError *err)
    {
        NSInteger errorCode = [OKNetworker getStatusCodeFromAFNetworkingError:err];
        
        // If the user is unsubscribed to the app, log out the user.
        if(errorCode == OK_UNSUBSCRIBED_USER_ERROR_CODE) {
            OKLogErr(@"Logging out current user b/c user is unsubscribed to app");
            [[OKManager sharedManager] logoutCurrentUser];
        }
        
        if(handler)
            handler(nil, err);
    };

    
    // Perform HTTP request
    AFHTTPRequestOperationManager *httpManager = [self httpManager];
    
    NSMutableURLRequest *request = [self requestWithMethod:method
                                                      path:path
                                                parameters:params];
    
    AFHTTPRequestOperation *operation = [httpManager HTTPRequestOperationWithRequest:request
                                                                             success:successBlock
                                                                             failure:failureBlock];
    
    [[httpManager operationQueue] addOperation:operation];
}


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
         completion:(void (^)(id responseObject, NSError *error))handler
{
    [self performWithMethod:@"GET"
                       path:path
                 parameters:params
                 completion:handler];
}


+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
        completion:(void (^)(id responseObject, NSError *error))handler
{
    [self performWithMethod:@"POST"
                       path:path
                 parameters:params
                 completion:handler];
}


+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
       completion:(void (^)(id responseObject, NSError *error))handler
{
    [self performWithMethod:@"PUT"
                       path:path
                 parameters:params
                 completion:handler];
}


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
                tag:(NSInteger)tag
         completion:(void (^)(id responseObject, NSError *error))handler
{
    [self performWithMethod:@"GET"
                       path:path
                 parameters:params
                 completion:handler];
}


+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
               tag:(NSInteger)tag
        completion:(void (^)(id responseObject, NSError *error))handler
{
    [self performWithMethod:@"POST"
                       path:path
                 parameters:params
                 completion:handler];
}


+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
              tag:(NSInteger)tag
       completion:(void (^)(id responseObject, NSError *error))handler
{
    [self performWithMethod:@"PUT"
                       path:path
                 parameters:params
                 completion:handler];
}

@end
