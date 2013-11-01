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


NSString *
Escape(NSString *unescaped) {
    NSString *s = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                      NULL,
                                                                      (CFStringRef)unescaped,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                      kCFStringEncodingUTF8 ));
    
    return s;
}

typedef void (^OKNetworkerBlock)(id responseObject, NSError * error);


static AFHTTPRequestOperationManager *__httpManager = nil;
static NSString *OK_SERVER_API_VERSION = @"v1";


@implementation OKNetworker

/*
+ (void)haveFunManu
{
    NSString *oauthHeaderParams = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@", @"oauth_consumer_key", appKey, @"oauth_nonce", nonce, @"oauth_signature_method", @"HMAC-SHA1", @"oauth_timestamp", timestamp, @"oauth_version", @"1.0"];
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@%@%@&%@", verb, Escape(scheme), Escape(host), Escape(path), Escape(oauthHeaderParams)];
    const char *cKey  = [[secretKey stringByAppendingString:@"&"] cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [signatureBaseString cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *signature = [HMAC base64EncodedStringWithOptions:NULL];

    NSLog(@"Signature is: %@", signature);

    _handler = handler;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", scheme, host, path]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];

    NSString *auth = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"%@\", oauth_timestamp=\"%@\", oauth_version=\"%@\"", appKey, nonce, Escape(signature), @"HMAC-SHA1", timestamp, @"1.0"];
    [request addValue:auth forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"GET"];


    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [_connections addObject:connection];
}
*/

/*
+ (void)haveMoreFun
{
    // This stuff goes in the following implementation of NSURLConnection's delegate:
    // - (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
    // {
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"ok_wildcard" ofType:@"der"];
            NSData *certificateData = [NSData dataWithContentsOfFile:path];
            NSArray *okCerts = @[ CFBridgingRelease(SecCertificateCreateWithData(kCFAllocatorDefault, CFBridgingRetain(certificateData))) ];
            SecTrustRef trust = challenge.protectionSpace.serverTrust;

            if (noErr == SecTrustSetAnchorCertificates(trust, CFBridgingRetain(okCerts))) {
                SecTrustResultType trustResult;
                if (noErr == SecTrustEvaluate(trust, &trustResult)) {
                    if (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified) {
                        [challenge.sender useCredential:[NSURLCredential credentialForTrust:trust] forAuthenticationChallenge:challenge];
                        return;
                    }
                }
            }
        }
        [challenge.sender cancelAuthenticationChallenge:challenge];
    // }
}
 */

+ (AFHTTPRequestOperationManager*)httpManager
{
    if(!__httpManager) {
        NSURL *baseEndpointURL = [NSURL URLWithString:[OKManager endpoint]];
        NSURL *endpointUrl = [NSURL URLWithString:OK_SERVER_API_VERSION relativeToURL:baseEndpointURL];  
        
        
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        
        AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
        AFHTTPResponseSerializer *respondSerializer = [AFHTTPResponseSerializer serializer];
        __httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:endpointUrl];
        [__httpManager setSecurityPolicy:policy];
        [__httpManager setRequestSerializer:requestSerializer];
        [__httpManager setResponseSerializer:respondSerializer];
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


    NSString *appKey = [OKManager appKey];
    NSString *secretKey = [OKManager secretKey];
    NSString *nonce = [OKUtils createUUID];
    NSString *timestamp = [NSString stringWithFormat:@"%d", (NSUInteger)[OKUtils timestamp]];


    NSString *oauthHeaderParams = [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
                                   @"oauth_consumer_key", appKey, @"oauth_nonce", nonce, @"oauth_signature_method", @"HMAC-SHA1",
                                   @"oauth_timestamp", timestamp, @"oauth_version", @"1.0"];


    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", method, Escape(absolutePath), Escape(oauthHeaderParams)];
    NSString *signatureKeyString = [NSString stringWithFormat:@"%@&", secretKey];
    NSData *signatureBaseData = [signatureBaseString dataUsingEncoding:NSASCIIStringEncoding];
    NSData *signatureKeyData = [signatureKeyString dataUsingEncoding:NSASCIIStringEncoding];
    NSData *HMAC = [OKCrypto HMACSHA1:signatureBaseData key:signatureKeyData];
    NSString *signature = [HMAC base64EncodedStringWithOptions:0];


    NSMutableString *auth = [NSMutableString string];
    [auth appendFormat:@"OAuth oauth_consumer_key=\"%@\", ", appKey];
    [auth appendFormat:@"oauth_nonce=\"%@\", ", nonce];
    [auth appendFormat:@"oauth_signature=\"%@\", ", Escape(signature)];
    [auth appendFormat:@"oauth_signature_method=\"HMAC-SHA1\", "];
    [auth appendFormat:@"oauth_timestamp=\"%@\", ", timestamp];
    [auth appendFormat:@"oauth_version=\"1.0\""];
    [request addValue:auth forHTTPHeaderField:@"Authorization"];

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
        if(handler) {
            id obj = OKDecodeObj(response, nil);
            handler(obj, nil);
        }
    };

    
    // FAILURE BLOCK
    void (^failureBlock)(AFHTTPRequestOperation*, NSError*) = ^(AFHTTPRequestOperation *op, NSError *err)
    {
        NSInteger errorCode = [OKNetworker getStatusCodeFromAFNetworkingError:err];

        OKLogErr(@"OKNetworking: %@\n%@\n\n", [op responseString], err);
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
