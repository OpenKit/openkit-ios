//
//  OKNetworker.m
//  OKNetworker
//
//  Created by Manuel Martinez-Almeida on 9/2/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKNetworker.h"
#import "OKManager.h"
#import "AFNetworking.h"


static AFHTTPClient* _httpClient = nil;

@implementation OKNetworker

+ (AFHTTPClient*) httpClient
{
    if(!_httpClient) {
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[OKManager getEndpoint]]];
        [_httpClient setParameterEncoding:AFJSONParameterEncoding];
        [_httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        
        // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
        [_httpClient setDefaultHeader:@"Accept" value:@"application/json"];
        [_httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
    }
    return _httpClient;
}


+ (NSMutableDictionary*) mergeParams:(NSDictionary*)d
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:d];
    if(![dict objectForKey:@"app_key"])
        [dict setValue:[OKManager getApplicationID] forKey:@"app_key"];
    
    return dict;
}


+ (void) requestWithMethod:(NSString*)method
                      path:(NSString*)path
                parameters:(NSDictionary*)params
                   handler:(void (^)(id responseObject, NSError* error))handler
{
    AFHTTPClient *httpclient = [self httpClient];
    params = [self mergeParams:params];
    
    NSMutableURLRequest *request = [httpclient requestWithMethod:method path:path parameters:params];
    AFHTTPRequestOperation *operation = [httpclient HTTPRequestOperationWithRequest:request success:
     ^(AFHTTPRequestOperation *operation, id responseObject)
     {
         handler(responseObject, nil);
         
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         
         handler(nil, error);
         
     }];
    
    [operation start];
}


+ (void) getFromPath:(NSString*)path
          parameters:(NSDictionary*)params
             handler:(void (^)(id responseObject, NSError* error))handler
{
    [self requestWithMethod:@"GET"
                       path:path
                 parameters:params
                    handler:handler];
}


+ (void) postToPath:(NSString*)path
         parameters:(NSDictionary*)params
            handler:(void (^)(id responseObject, NSError* error))handler
{
    [self requestWithMethod:@"POST"
                       path:path
                 parameters:params
                    handler:handler];
}


+ (void) putToPath:(NSString*)path
        parameters:(NSDictionary*)params
           handler:(void (^)(id responseObject, NSError* error))handler
{
    [self requestWithMethod:@"PUT"
                       path:path
                 parameters:params
                    handler:handler];
}


@end
