//
//  OKManager.h
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OKAnalytics : NSObject

+ (void)startSession;
+ (void)endSession;
+ (void)sendReportWithCompletion:(void(^)(NSError*error))handler;
+ (void)postEvent:(NSString*)typeName metadata:(id)metadata;

@end

