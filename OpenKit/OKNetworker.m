//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#define USE_JSONKIT  1


#import "OKNetworker.h"
#import "OKManager.h"
#import "AFNetworking.h"
#import "AFOAuth1Client.h"
#import "OKUtils.h"
#import "OKMacros.h"

static AFOAuth1Client *_httpClient = nil;
static NSString *OK_SERVER_API_VERSION = @"v1";

@implementation OKNetworker


+ (AFOAuth1Client *)httpClient
{
    if(!_httpClient) {
        NSURL *baseEndpointURL = [NSURL URLWithString:[OKManager endpoint]];
        NSURL *endpointUrl = [NSURL URLWithString:OK_SERVER_API_VERSION relativeToURL:baseEndpointURL];
        NSString *endpointString = [endpointUrl absoluteString];
        
        OKLog(@"Initializing AFOauth1Client with endpoint: %@",endpointString);
        _httpClient = [[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:endpointString]
                                                          key:[OKManager appKey]
                                                       secret:[OKManager secretKey]];
        [_httpClient setParameterEncoding:AFJSONParameterEncoding];
        [_httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    }
    return _httpClient;
}

+ (void)requestWithMethod:(NSString *)method
                     path:(NSString *)path
               parameters:(NSDictionary *)params
                  handler:(void (^)(id responseObject, NSError * error))handler
{
    AFOAuth1Client *httpclient = [self httpClient];
    NSMutableURLRequest *request = [httpclient requestWithMethod:method
                                                            path:path
                                                      parameters:params];

    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id response) {
        NSError *err;
        BOOL empty = ([response length] == 1) && ((uint8_t *)[response bytes])[0] == ' ';
        if (empty) {
            handler(nil, err);
        } else {
            id decodedObj = OKDecodeObj(response, &err);
            handler(decodedObj, err);
        }
    };

    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *err) {
        handler(nil, err);
    };

    AFHTTPRequestOperation *op = [httpclient HTTPRequestOperationWithRequest:request
                                                                     success:successBlock
                                                                     failure:failureBlock];
    [op start];
}

+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
            handler:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"GET"
                       path:path
                 parameters:params
                    handler:handler];
}

+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
           handler:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"POST"
                       path:path
                 parameters:params
                    handler:handler];
}

+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
          handler:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"PUT"
                       path:path
                 parameters:params
                    handler:handler];
}


@end
