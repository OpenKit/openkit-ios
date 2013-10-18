//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//


#import "OKNetworker.h"
#import "OKManager.h"
#import "AFNetworking.h"
#import "AFOAuth1Client.h"
#import "OKUtils.h"
#import "OKMacros.h"
#import "OKError.h"


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


+ (int)getStatusCodeFromAFNetworkingError:(NSError*)error {
    if([[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey]) {
        return [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
    } else {
        return 0;
    }
}


+ (NSDictionary*)encryptMessage:(NSDictionary*)params withError:(NSError**)error
{
    NSData *payload;
    
    // Generate JSON UTF-8 encoded
    payload = [NSJSONSerialization dataWithJSONObject:params options:0 error:error];
    
    // Encrypt payload
    payload = [[[OKManager sharedManager] cryptor] encryptData:payload];
    
    
    // Generate dictionary
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"SHA256_AES256", @"encryption",
                          @"UTF-8", @"encoding",
                          @"payload", [OKUtils base64Enconding:payload], nil];
    
    return dict;
}


+ (NSDictionary*)decryptMessage:(NSDictionary*)params withError:(NSError**)error
{
    // Convert base64 encoded string to NSData
    NSData *payload = [OKUtils base64Decoding:[params objectForKey:@"payload"]];
    
    // Decrypt payload using algorithm
    NSString *encryption = [params objectForKey:@"encryption"];
    if([encryption isEqualToString:@"SHA256_AES256"])
        payload = [[[OKManager sharedManager] cryptor] decryptData:payload];
    
    else {
        OKLogErr(@"Not valid encryption: %@", encryption);
        // REVIEW
        *error = [OKError unknownError];
        return nil;
    }
    
    // Generate NSDictionary from JSON data
    return [NSJSONSerialization JSONObjectWithData:payload options:0 error:error];
}


+ (BOOL)isMessageEncrypted:(NSDictionary*)dict
{
    return [dict objectForKey:@"encryption"] && [dict objectForKey:@"encoding"] && [dict objectForKey:@"payload"];
}


+ (void)requestWithMethod:(NSString *)method
                     path:(NSString *)path
               parameters:(NSDictionary *)params
                encrypted:(BOOL)encrypted
               completion:(void (^)(id responseObject, NSError * error))handler
{
    if(encrypted) {
        NSDictionary *encryptedParams = [OKNetworker encryptMessage:params withError:nil];
        if(!encryptedParams)
            OKLogErr(@"Error while generating encrypted message.");
        else
            params = encryptedParams;
    }
    
    AFOAuth1Client *httpclient = [self httpClient];
    NSMutableURLRequest *request = [httpclient requestWithMethod:method
                                                            path:path
                                                      parameters:params];

    void (^successBlock)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id response) {
        NSError *err;
        BOOL empty = ([response length] == 1) && ((uint8_t *)[response bytes])[0] == ' ';
        if (empty) {
            handler(nil, nil);
        } else {
            id decodedObj = OKDecodeObj(response, &err);
            if (decodedObj == [NSNull null]) {
                decodedObj = nil;
                err = [OKError noBodyError];
            }else{
                if([OKNetworker isMessageEncrypted:decodedObj]) {
                    decodedObj = [OKNetworker decryptMessage:decodedObj withError:&err];
                }
            }
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
         completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"GET"
                       path:path
                 parameters:params
                  encrypted:NO
                 completion:handler];
}


+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
        completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"POST"
                       path:path
                 parameters:params
                  encrypted:NO
                 completion:handler];
}


+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
       completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"PUT"
                       path:path
                 parameters:params
                  encrypted:NO
                 completion:handler];
}


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
          encrypted:(BOOL)encrypted
         completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"GET"
                       path:path
                 parameters:params
                  encrypted:encrypted
                 completion:handler];
}

+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
         encrypted:(BOOL)encrypted
        completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"POST"
                       path:path
                 parameters:params
                  encrypted:encrypted
                 completion:handler];
}

+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
        encrypted:(BOOL)encrypted
       completion:(void (^)(id responseObject, NSError *error))handler
{
    [self requestWithMethod:@"PUT"
                       path:path
                 parameters:params
                  encrypted:encrypted
                 completion:handler];
}


@end
