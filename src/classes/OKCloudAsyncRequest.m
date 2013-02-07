//
//  OKCloudAsyncRequest.m
//  OKClient
//
//  Created by Louis Zell on 1/25/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKCloudAsyncRequest.h"
#import "OKDirector.h"
#import "AFNetworking.h"


@implementation OKCloudAsyncRequest

- (NSDictionary *)headers
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"application/json", @"Accept",
                          @"application/json", @"Content-Type",
                          nil];
    return dict;
}

- (AFHTTPClient *)httpClient
{
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:OKBaseURL]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    return client;
}


- (id)initWithPath:(NSString *)path requestMethod:(NSString *)meth parameters:(NSDictionary *)params
{
    if ((self = [super init])) {
        _path = path;
        _requestMethod = meth;
        _params = params;
    }
    return self;
}

- (void)performWithCompletionHandler:(void (^)(id responseObject, NSError *err))completion
{
    AFHTTPClient *httpclient = [self httpClient];
    NSMutableURLRequest *request = [httpclient requestWithMethod:self.requestMethod
                                                            path:self.path
                                                      parameters:self.mergedParams];

    // Default httpclient headers are overwritten based on parameterEncoding property.
    // Reset them to the defaults we want here.
    [[self headers] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];

    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        OKLog(@"OKCloudAsyncRequest Response: %@", responseObject);
        completion(responseObject, nil);
    };

    void (^failureBlock)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        OKLog(@"OKCloudAsyncRequest failed: %@", error);
        completion(nil, error);
    };

    AFHTTPRequestOperation *op = [httpclient HTTPRequestOperationWithRequest:request
                                                                     success:successBlock
                                                                     failure:failureBlock];

    [op start];
}

#pragma mark - Custom Getters
- (NSMutableDictionary *)mergedParams
{
    if (!_mergedParams) {
        _mergedParams = [NSMutableDictionary dictionaryWithObject:[OpenKit getApplicationID] forKey:@"app_key"];
        [_mergedParams addEntriesFromDictionary:_params];
    }
    return _mergedParams;
}


@end
