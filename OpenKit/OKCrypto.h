//
//  OKCrypto.h
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKCrypto : NSObject

+ (uint64_t)randomInt64;
- (id)initWithMasterKey:(NSString*)key;
- (NSData*)encryptData:(NSData*)data;
- (NSData*)decryptData:(NSData*)data;

@end

