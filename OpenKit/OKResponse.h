//
//  OKResponse.h
//  OpenKit
//
//  Created by Louis Zell on 10/31/13.
//
//

#import <Foundation/Foundation.h>

@interface OKResponse : NSObject

@property (nonatomic, copy) NSData *body;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, assign) int statusCode;

@end
