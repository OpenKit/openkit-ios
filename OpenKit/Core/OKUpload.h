//
//  OKUpload.h
//  OpenKit
//
//  Created by Louis Zell on 10/31/13.
//
//

#import <Foundation/Foundation.h>

@interface OKUpload : NSObject

@property(nonatomic, assign) NSData *buffer;
@property(nonatomic) NSString *compression;
@property(nonatomic, readwrite) NSString *type;
@property(nonatomic, retain) NSString *paramName;

- (id)initWithData:(NSData*)data type:(NSString*)type compress:(BOOL)compress;
@end
