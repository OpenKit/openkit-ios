//
//  OKRequest.m
//  OpenKit
//
//  Created by Louis Zell on 10/26/13.
//
//

#import "OKRequest.h"
#import "OKRequestUtils.h"
#import "OKResponse.h"
#import "OKUpload.h"
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>


@interface OKRequest ()
{
    NSString *_appKey;
    NSString *_secretKey;
    NSNumber *_timestamp;
    NSString *_nonce;
    NSString *_scheme;
    NSString *_host;

    OKResponse *_response;
    OKUpload *_upload;
    NSString *_verb;
    NSString *_path;
    NSDictionary *_queryParams;
    NSDictionary *_reqParams;
    NSMutableDictionary *_paramsInSignature;
    NSData *_requestBody;
    NSURL *_url;
    NSMutableData *_receivedData;
    NSMutableArray *_connections;
}

@property (nonatomic, strong) void(^handler)(OKResponse *response);

@end


@implementation OKRequest


- (id)init
{
    if ((self = [super init])) {
        _appKey    = @"end_to_end_test";
        _secretKey = @"TL5GGqzfItqZErcibsoYrNAuj7K33KpeWUEAYyyU";
        _timestamp = @((int)[[NSDate date] timeIntervalSince1970]);
        _nonce     = [[NSUUID UUID] UUIDString];
        _scheme    = @"https";
        _host      = @"local.openkit.io";
        _paramsInSignature = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
             _appKey,         @"oauth_consumer_key",
             _nonce,          @"oauth_nonce",
             @"HMAC-SHA1",    @"oauth_signature_method",
             _timestamp,      @"oauth_timestamp",
             @"1.0",          @"oauth_version",
         nil
        ];
        _response = [[OKResponse alloc] init];
    }
    return self;
}

#pragma mark - Public API
- (void)get:(NSString *)path queryParams:(NSDictionary *)queryParams complete:(void(^)(OKResponse *))handler
{
    [self request:@"GET" path:path queryParams:queryParams reqParams:nil upload:nil complete:handler];
}

- (void)post:(NSString *)path reqParams:(NSDictionary *)reqParams complete:(void(^)(OKResponse *))handler
{
    [self request:@"POST" path:path queryParams:nil reqParams:reqParams upload:nil complete:handler];
}

- (void)multiPost:(NSString *)path reqParams:(NSDictionary *)reqParams upload:(OKUpload *)upload complete:(void(^)(OKResponse *))handler
{
    [self request:@"POST" path:path queryParams:nil reqParams:reqParams upload:upload complete:handler];
}

- (void)put:(NSString *)path reqParams:(NSDictionary *)reqParams complete:(void(^)(OKResponse *))handler
{
    [self request:@"PUT" path:path queryParams:nil reqParams:reqParams upload:nil complete:handler];
}

- (void)del:(NSString *)path complete:(void(^)(OKResponse *))handler
{
    [self request:@"DELETE" path:path queryParams:nil reqParams:nil upload:nil complete:handler];
}


#pragma mark - General API
- (void)request:(NSString *)verb
           path:(NSString *)path
    queryParams:(NSDictionary *)queryParams
      reqParams:(NSDictionary *)reqParams
         upload:(OKUpload *)upload
       complete:(void(^)(OKResponse *))handler
{
    _verb = verb;
    _path = path;
    _queryParams = queryParams;
    _reqParams = reqParams;
    _handler = handler;
    _upload = upload;

    if ([self isGet])
        [_paramsInSignature addEntriesFromDictionary:queryParams];


    if ([self isPut] || [self isPost]) {
        NSError *jsonErr;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:reqParams
                                                           options:NULL
                                                             error:&jsonErr];
        if (!jsonData) {
            NSLog(@"Got an error: %@", jsonErr);
        } else {
            _requestBody = jsonData;
        }
    }

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[self url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];

    [request setHTTPMethod:_verb];
    if ([self isMultipart]) {
        NSString *boundary = OKNewBoundaryString();
        [request addValue:OKMultiPartContentType(boundary) forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:OKMultiPartPostBody(_reqParams, _upload, boundary)];
    } else {
        [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }

    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"close" forHTTPHeaderField:@"Connection"];
    [request addValue:[self authorizationHeader] forHTTPHeaderField:@"Authorization"];

    if (_requestBody)
        [request setHTTPBody:_requestBody];


    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [_connections addObject:connection];
}

- (BOOL)isGet
{
    return ([_verb isEqualToString:@"GET"]);
}

- (BOOL)isPut
{
    return ([_verb isEqualToString:@"PUT"]);
}

- (BOOL)isPost
{
    return (([_verb isEqualToString:@"POST"]) && _upload == nil);
}

- (BOOL)isMultipart
{
    return (([_verb isEqualToString:@"POST"]) && _upload);
}

- (NSURL *)url
{
    if (_url == nil) {
        if ([self isGet] && _queryParams) {
            _url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?%@", [self baseUri], _path, OKParamsToQuery(_queryParams)]];
        } else {
            _url = [NSURL URLWithString:[[self baseUri] stringByAppendingString:_path]];
        }
    }
    return _url;
}

- (NSString *)baseUri
{
    return [NSString stringWithFormat:@"%@://%@", _scheme, _host];
}


#pragma mark - Signature API (private)
- (NSString *)paramsStringForSignature
{
    NSArray *sortedKeys = [[_paramsInSignature allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSMutableArray *parts = [NSMutableArray array];
    [sortedKeys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", key, [_paramsInSignature objectForKey:key]]];
    }];

    return [parts componentsJoinedByString:@"&"];
}

- (NSString *)signature
{
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", _verb, OKEscape([[self baseUri] stringByAppendingString:_path]), OKEscape([self paramsStringForSignature])];

    NSString *k = [_secretKey stringByAppendingString:@"&"];

    const char *cKey  = [k cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [signatureBaseString cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *signature = [HMAC base64EncodedStringWithOptions:NULL];
    return signature;
}

- (NSString *)authorizationHeader
{
    return [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"%@\", oauth_version=\"1.0\"",
            _appKey,
            _nonce,
            OKEscape([self signature]),
            _timestamp
           ];
}


#pragma mark - NSURLConnection Delegate Implementation
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _response.error = error;
    if (_handler)
        _handler(_response);
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
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
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response.statusCode = [(NSHTTPURLResponse*)response statusCode];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!_receivedData)
        _receivedData = [data mutableCopy];
    else
       [_receivedData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _response.body = _receivedData;
    if (_handler)
        _handler(_response);
}

@end
