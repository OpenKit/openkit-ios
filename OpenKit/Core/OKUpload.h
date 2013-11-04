//
//  OKUpload.h
//  OpenKit
//
//  Created by Louis Zell on 10/31/13.
//
//

#import <Foundation/Foundation.h>

@interface OKUpload : NSObject

@property (nonatomic, assign) NSData *buffer;
@property (nonatomic, retain) NSString *paramName;

@end
