//
//  OKResponse.m
//  OpenKit
//
//  Created by Louis Zell on 10/31/13.
//
//

#import "OKResponse.h"
#import "OKMacros.h"


@implementation OKResponse

- (void)process
{
    _backendError = nil;
    _jsonObject = nil;
    _jsonError = nil;

    if(!_networkError && !_SSLError) {
        if(_statusCode >= 400) {
            // BACKEND ERROR
            NSString *body = [[NSString alloc] initWithData:_body encoding:NSUTF8StringEncoding];
            _backendError = [NSError errorWithDomain:@"OKResponseDomain" code:_statusCode userInfo:@{@"NSLocalizedFailureReasonErrorKey":body }];

        }else{
            NSJSONReadingOptions opts = NSJSONReadingAllowFragments | NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves;
            NSError *error;
            _jsonObject = [NSJSONSerialization JSONObjectWithData:_body options:opts error:&error];
            _jsonError = [error copy];
        }
    }

    NSError *error = [self error];
    if(error)
        OKLogErr(@"OKResponse: %@\n", error);
}


- (NSError*)error
{
    if(_SSLError)
        return _SSLError;

    if(_networkError)
        return _networkError;

    if(_backendError)
        return _backendError;

    if(_jsonError)
        return _jsonError;

    return nil;
}

@end
