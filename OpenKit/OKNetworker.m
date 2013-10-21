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
#import "OKPrivate.h"


static AFOAuth1Client *_httpClient = nil;
static NSString *OK_SERVER_API_VERSION = @"v2";

@implementation OKNetworker

+ (AFOAuth1Client*)httpClient
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


+ (int)getStatusCodeFromAFNetworkingError:(NSError*)error
{
    if([[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey]) {
        return [[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey] statusCode];
    } else {
        return 0;
    }
}


+ (NSDictionary*)encryptMessage:(NSDictionary*)params withError:(NSError**)error
{
    if(!params)
        return nil;
    
    // Generate JSON UTF-8 encoded
    NSData *payload = [NSJSONSerialization dataWithJSONObject:params options:0 error:error];
    if(!payload)
        return nil;
    
    // Encrypt payload
    payload = [[[OKManager sharedManager] cryptor] encryptData:payload];
    if(!payload) {
        if(error)
        *error = [OKError unknownError];
        return nil;
    }
    // Generate dictionary
    return @{@"encryption": @"SHA256_AES256",
             @"encoding": @"UTF-8",
             @"payload": [OKUtils base64Enconding:payload] };
}


+ (NSDictionary*)decryptMessage:(NSDictionary*)params withError:(NSError**)error
{
    if(!params)
        return nil;
    
    // Convert base64 encoded string to NSData
    NSData *payload = [OKUtils base64Decoding:params[@"payload"]];
    
    // Decrypt payload using algorithm
    NSString *encryption = params[@"encryption"];
    if([encryption isEqualToString:@"SHA256_AES256"])
        payload = [[[OKManager sharedManager] cryptor] decryptData:payload];
    
    else {
        OKLogErr(@"Not valid encryption: %@", encryption);
        // REVIEW
        if(error)
            *error = [OKError unknownError];
        return nil;
    }
    
    // Generate NSDictionary from JSON data
    return [NSJSONSerialization JSONObjectWithData:payload options:0 error:error];
}


+ (BOOL)isMessageEncrypted:(NSDictionary*)dict
{
    return (dict && dict[@"encryption"] && dict[@"encoding"] && dict[@"payload"]);
}


+ (void)requestWithMethod:(NSString *)method
                     path:(NSString *)path
               parameters:(NSDictionary *)params
                encrypted:(BOOL)encrypted
               completion:(void (^)(id responseObject, NSError * error))handler
{
    // ENCRYPT MESSAGE
    if(encrypted) {
        NSDictionary *encryptedParams = [OKNetworker encryptMessage:params withError:nil];
        if(!encryptedParams)
            OKLogErr(@"Error while generating encrypted message.");
        else
            params = encryptedParams;
    }

    
    // SUCCESS BLOCK
    void (^successBlock)(AFHTTPRequestOperation*, id) = ^(AFHTTPRequestOperation *op, id response)
    {
        NSError *err;
        id decodedObj = OKDecodeObj(response, &err);
        if([OKNetworker isMessageEncrypted:decodedObj]) {
            decodedObj = [OKNetworker decryptMessage:decodedObj withError:&err];
        }
        
        if(handler)
        handler(decodedObj, err);
    };

    
    // FAILURE BLOCK
    void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^(AFHTTPRequestOperation *op, NSError *err)
    {
        int errorCode = [OKNetworker getStatusCodeFromAFNetworkingError:err];
        
        // If the user is unsubscribed to the app, log out the user.
        if(errorCode == OK_UNSUBSCRIBED_USER_ERROR_CODE) {
            [[OKManager sharedManager] logoutCurrentUser];
            OKLog(@"Logging out current user b/c user is unsubscribed to app");
        }
        
        if(handler)
        handler(nil, err);
    };

    
    // Perform HTTP request
    AFOAuth1Client *httpclient = [self httpClient];
    
    NSMutableURLRequest *request = [httpclient requestWithMethod:method
                                                            path:path
                                                      parameters:params];
    
    AFHTTPRequestOperation *operation = [httpclient HTTPRequestOperationWithRequest:request
                                                                            success:successBlock
                                                                            failure:failureBlock];
    
    [operation start];
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
