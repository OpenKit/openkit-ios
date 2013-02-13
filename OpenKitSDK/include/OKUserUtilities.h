//
//  OKUserUtilities.h
//  OKClient
//
//  Created by Suneet Shah on 1/8/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OKUser;
@interface OKUserUtilities : NSObject

+ (OKUser *)createOKUserWithJSONData:(NSDictionary *)jsonData;
+ (NSDictionary *)getJSONRepresentationOfUser:(OKUser *)user;
+ (void)updateUserNickForOKUser:(OKUser *)user withNewNick:(NSString *)newNick withCompletionHandler:(void(^)(NSError *error))completionHandler;

@end
