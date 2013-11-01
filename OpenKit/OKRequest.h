//
//  OKRequest.h
//  OpenKit
//
//  Created by Louis Zell on 10/26/13.
//
//

/** API Example:

 void (^handler)(OKResponse *) = ^void(OKResponse *response) {
   if (!response.error)
     NSLog(@"Response code: %i, Response body: %@", response.statusCode, [NSString stringWithUTF8String:[response.body bytes]]);
   else
     NSLog(@"Request failed with error: %@", [response.error localizedDescription]);
 };

 [[OKRequest new] post:@"/v1/users" reqParams:@{ @"user": @{ @"nick": @"lou z", @"custom_id": @"454" }} complete:handler];
*/

#import <Foundation/Foundation.h>

@class OKResponse;
@class OKUpload;

@interface OKRequest : NSObject

- (void)get:(NSString *)path queryParams:(NSDictionary *)queryParams complete:(void(^)(OKResponse *))handler;

- (void)put:(NSString *)path reqParams:(NSDictionary *)reqParams complete:(void(^)(OKResponse *))handler;

- (void)post:(NSString *)path reqParams:(NSDictionary *)reqParams complete:(void(^)(OKResponse *))handler;

- (void)multiPost:(NSString *)path reqParams:(NSDictionary *)reqParams upload:(OKUpload *)upload complete:(void(^)(OKResponse *))handler;

- (void)del:(NSString *)path complete:(void(^)(OKResponse *))handler;

- (void)request:(NSString *)verb
           path:(NSString *)path
    queryParams:(NSDictionary *)queryParams
      reqParams:(NSDictionary *)reqParams
         upload:(OKUpload *)upload
       complete:(void(^)(OKResponse *))handler;

@end
