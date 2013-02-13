//
//  OKCloudAsyncRequest.h
//  OKClient
//
//  Created by Louis Zell on 1/25/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKCloudAsyncRequest : NSObject

- (id)initWithPath:(NSString *)path requestMethod:(NSString *)meth parameters:(NSDictionary *)params;
- (void)performWithCompletionHandler:(void (^)(id responseObject, NSError *err))completion;

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *requestMethod;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSMutableDictionary *mergedParams;        // Has custom getter

@end
