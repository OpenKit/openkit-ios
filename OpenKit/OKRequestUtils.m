//
//  OKRequestUtils.m
//  OpenKit
//
//  Created by Louis Zell on 11/1/13.
//
//

#import "OKRequestUtils.h"
#import "OKUpload.h"

NSString *
OKEscape(NSString *unescaped) {
    NSString *s = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                      NULL,
                                                                      (CFStringRef)unescaped,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                      kCFStringEncodingUTF8 );

    return [s autorelease];
}


NSDictionary *
OKFlattenParams(NSDictionary *parameters)
{
    NSMutableDictionary *flattened = [NSMutableDictionary new];
    OKParamPairs(parameters, nil, ^(NSDictionary *pair) {
        [flattened addEntriesFromDictionary:pair];
    });
    return [NSDictionary dictionaryWithDictionary:flattened];
}


void
OKParamPairs(NSDictionary *parameters, NSString *running, void (^block)(NSDictionary *pair))
{
    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop)
     {
         NSString *name;
         if (!running)
             name = key;
         else
             name = [NSString stringWithFormat:@"%@[%@]", running, key];

         if ([obj isKindOfClass:[NSDictionary class]])
             OKParamPairs(obj, name, block);
         else
             block(@{name : obj});
     }];
}


NSString *
OKParamsToQuery(NSDictionary *dict)
{
    if ([dict count] == 0)
        return @"";

    NSMutableArray *parts = [NSMutableArray array];
    [dict enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@",key,obj]];
    }];

    return [parts componentsJoinedByString:@"&"];
}


NSString *
OKNewBoundaryString(void)
{
    static const char alphanum[] =
    "0123456789"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz";
    int len = 16;
    char s[16];
    for(int i = 0; i < len; i++) {
        s[i] = alphanum[arc4random() % (sizeof(alphanum) - 1)];
    }
    s[len] = '\0';
    return [[NSString alloc] initWithFormat:@"--OKForm%s", s];
}


NSString *
OKMultiPartContentType(NSString *boundary)
{
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, boundary];
}


NSData *
OKMultiPartPostBody(NSDictionary *params, OKUpload *upload, NSString *boundary)
{
    NSString *firstLine    = [NSString stringWithFormat:@"--%@\r\n", boundary];
    NSString *boundaryLine = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
    NSString *endLine      = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];

    NSMutableData *pData = [NSMutableData data];
    NSDictionary *flatParams = OKFlattenParams(params);

    [pData appendData:[firstLine dataUsingEncoding:NSUTF8StringEncoding]];
    [flatParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [pData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];

        if ([obj isKindOfClass:[NSNumber class]])
            [pData appendData:[[obj stringValue] dataUsingEncoding:NSUTF8StringEncoding]];
        else
            [pData appendData:[obj dataUsingEncoding:NSUTF8StringEncoding]];

        [pData appendData:[boundaryLine dataUsingEncoding:NSUTF8StringEncoding]];
    }];

    [pData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", @"whateverguy.txt"] dataUsingEncoding:NSUTF8StringEncoding]];
    [pData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [pData appendData:upload.buffer];
    [pData appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
    return pData;
}

