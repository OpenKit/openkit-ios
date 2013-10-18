//
//  OKCrypto.h
//  OpenKit
//
//  Created by Manu Mtz-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKCrypto : NSObject

+ (uint64_t)randomInt64;
+ (NSData*)HMACSHA256:(NSData*)data withKey:(NSString*)key;
+ (NSData*)AES256EncryptData:(NSData*)data withKey:(NSString*)key;
+ (NSData*)AES256DecryptData:(NSData*)data withKey:(NSString *)key;
+ (NSData*)SHA256_AES256EncryptData:(NSData*)data withKey:(NSString *)key;
+ (NSData*)SHA256_AES256DecryptData:(NSData*)data withKey:(NSString *)key;

@end

