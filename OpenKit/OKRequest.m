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
#import "OKUtils.h"
#import "OKMacros.h"


static NSString *__SSLFilename = @"ok_wildcard";
static NSData *__SSLData = nil;
static id __SSLCertificate = nil;

@interface OKRequest ()
{
    NSURL *_baseURI;

    OKClient *_client;
    OKLocalUser *_user;
    NSMutableDictionary *_paramsInHeader;

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

    NSError *_sslError;
}

@property (nonatomic, strong) void(^handler)(OKResponse *response);

@end


@implementation OKRequest

+ (id)SSLCertificate
{
    if(!__SSLCertificate) {
        if(!__SSLData) {
            if(!__SSLFilename) {
                OKLogErr(@"Not filename/data provided");
                return nil;
            }

            NSString *path = [[NSBundle mainBundle] pathForResource:__SSLFilename ofType:@"der"];
            __SSLData = [NSData dataWithContentsOfFile:path];
            if(!__SSLData) {
                OKLogErr(@"Imposible to load SSL certificate.");
                return nil;
            }
        }

        __SSLCertificate = CFBridgingRelease(SecCertificateCreateWithData(kCFAllocatorDefault, CFBridgingRetain(__SSLData)));
        if(!__SSLCertificate) {
            OKLogErr(@"Invalid certificate.");
            return nil;
        }else{
            __SSLData = nil;
        }
    }
    return __SSLCertificate;
}


+ (void)setSSLCertificate:(NSData*)data
{
    __SSLCertificate = nil;
    __SSLFilename = nil;
    __SSLData = data;
}


+ (void)setSSLCertificateName:(NSString*)name
{
    __SSLCertificate = nil;
    __SSLData = nil;
    __SSLFilename = name;
}


- (id)initWithClient:(OKClient*)client user:(OKLocalUser*)user;
{
    if ((self = [super init])) {

        _client     = client;
        _user       = user;
        _baseURI    = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", [_client host]]];


        NSDictionary *defaultParams = @{@"oauth_consumer_key": [_client consumerKey],
                                        @"oauth_nonce": [OKUtils createUUID],
                                        @"oauth_signature_method": @"HMAC-SHA1",
                                        @"oauth_timestamp": @((NSUInteger)[OKUtils timestamp]),
                                        @"oauth_version": @"1.0" };



        _response = [[OKResponse alloc] init];
        _paramsInHeader = [NSMutableDictionary dictionaryWithDictionary:defaultParams];
        _paramsInSignature = [NSMutableDictionary dictionaryWithDictionary:defaultParams];

        if (_user) {
            [_paramsInHeader setObject:[_user accessToken] forKey:@"oauth_token"];
            [_paramsInSignature setObject:[_user accessToken] forKey:@"oauth_token"];
        }
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
                                                           options:0
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

- (NSURL *)finalPath
{
    return [NSURL URLWithString:_path relativeToURL:_baseURI];
}

- (NSURL *)url
{
    if (_url == nil) {
        if ([self isGet] && _queryParams) {
            _url = [NSURL URLWithString:OKParamsToQuery(_queryParams) relativeToURL:[self finalPath]];
        } else {
            _url = [self finalPath];
        }
    }
    return _url;
}


#pragma mark - Signature API (private)

- (NSString*)paramsStringForSignature
{
    NSArray *sortedKeys = [[_paramsInSignature allKeys] sortedArrayUsingSelector: @selector(compare:)];
    NSMutableArray *parts = [NSMutableArray array];

    [sortedKeys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", key, [_paramsInSignature objectForKey:key]]];
    }];

    return [parts componentsJoinedByString:@"&"];
}


- (NSString *)authorizationHeader
{
    [_paramsInHeader setObject:OKEscape([self signature]) forKey:@"oauth_signature"];

    NSMutableArray *parts = [NSMutableArray arrayWithCapacity:[_paramsInHeader count]];
    [_paramsInHeader enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, value]];
    }];

    return [@"OAuth " stringByAppendingString:[parts componentsJoinedByString:@", "]];
}


- (NSString *)signature
{
    NSString *accessTokenSecret = _user ? [_user accessTokenSecret] : @"";
    NSString *finalPath = [[self finalPath] absoluteString];

    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", _verb, OKEscape(finalPath), OKEscape([self paramsStringForSignature])];
    NSString *signatureKeyString = [NSString stringWithFormat:@"%@&%@", [_client consumerSecret], accessTokenSecret];

    NSData *signatureBaseData = [signatureBaseString dataUsingEncoding:NSASCIIStringEncoding];
    NSData *signatureKeyData = [signatureKeyString dataUsingEncoding:NSASCIIStringEncoding];

    NSData *HMAC = [OKCrypto HMACSHA1:signatureBaseData key:signatureKeyData];
    return [OKUtils base64Enconding:HMAC];
}


#pragma mark - NSURLConnection Delegate Implementation

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSAssert(_response, @"Response can not be nil");

    [_response setSSLError:_sslError];
    [_response setNetworkError:error];
    [_response process];

    if (_handler)
        _handler(_response);
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        _sslError = [NSError errorWithDomain:@"OKRequestDomain" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:@"Fail SecTrustSetAnchorCertificates()."}];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return;
    }
    id cer = [OKRequest SSLCertificate];
    if(!cer) {
        _sslError = [NSError errorWithDomain:@"OKRequestDomain" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:@"Fail SecTrustSetAnchorCertificates()."}];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return;
    }
    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    if (SecTrustSetAnchorCertificates(trust, CFBridgingRetain(@[cer])) != noErr) {
        _sslError = [NSError errorWithDomain:@"OKRequestDomain" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:@"Fail SecTrustSetAnchorCertificates()."}];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return;
    }

    SecTrustResultType trustResult;
    if (SecTrustEvaluate(trust, &trustResult) != noErr) {
        _sslError = [NSError errorWithDomain:@"OKRequestDomain" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:@"Fail SecTrustEvaluate()."}];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return;
    }

    if (trustResult != kSecTrustResultProceed && trustResult != kSecTrustResultUnspecified) {
        _sslError = [NSError errorWithDomain:@"OKRequestDomain" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey:@"Certificate doesn't match."}];
        [challenge.sender cancelAuthenticationChallenge:challenge];
        return;
    }


    [challenge.sender useCredential:[NSURLCredential credentialForTrust:trust] forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [_response setStatusCode:[(NSHTTPURLResponse*)response statusCode]];
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
    [_response setBody:_receivedData];
    [_response process];
    if (_handler)
        _handler(_response);
}

@end
