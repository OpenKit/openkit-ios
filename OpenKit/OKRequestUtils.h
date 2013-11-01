//
//  OKRequestUtils.h
//  OpenKit
//
//  Created by Louis Zell on 11/1/13.
//
//

#import <Foundation/Foundation.h>

@class OKUpload;


NSString *OKEscape(NSString *unescaped);

NSDictionary *OKFlattenParams(NSDictionary *parameters);

void OKParamPairs(NSDictionary *parameters, NSString *running, void (^block)(NSDictionary *pair));

NSString *OKParamsToQuery(NSDictionary *dict);

NSString *OKNewBoundaryString(void);

NSString *OKMultiPartContentType(NSString *boundary);

NSData *OKMultiPartPostBody(NSDictionary *params, OKUpload *upload, NSString *boundary);