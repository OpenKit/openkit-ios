//
//  OKResponse.h
//  OpenKit
//
//  Created by Louis Zell on 10/31/13.
//
//

#import <Foundation/Foundation.h>

@interface OKResponse : NSObject

@property(nonatomic, readonly) id jsonObject;
@property(nonatomic, strong) NSData *body;
@property(nonatomic, strong) NSError *SSLError;
@property(nonatomic, strong) NSError *networkError;
@property(nonatomic, strong) NSError *backendError;
@property(nonatomic, strong) NSError *jsonError;
@property(nonatomic, readwrite) int statusCode;

- (void)process;
- (NSError*)error;

@end
