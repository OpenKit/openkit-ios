//
//  OKCrypto.h
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OKCrypto : NSObject

- (id)initWithMasterKey:(NSString*)key;
- (NSData*)encryptData:(NSData*)data;
- (NSData*)decryptData:(NSData*)data;


+ (uint64_t)randomInt64;
+ (NSData*)derivateKey:(NSData*)key withString:(NSString*)string;
+ (NSData*)HMACSHA256:(NSData*)data key:(NSData*)key;
+ (NSData*)HMACSHA1:(NSData*)data key:(NSData*)key;
+ (NSData*)SHA256:(NSData*)data;

@end
