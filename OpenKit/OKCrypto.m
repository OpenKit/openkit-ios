//
//  OKCrypto.m
//  OpenKit
//
//  Created by Manu Mtz-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <Security/Security.h>
#import "OKCrypto.h"
#import "OKMacros.h"


static void HMACSHA256(const char *data, int dataLength,
                     const char *key, int keyLength,
                     uint8_t digest[CC_SHA1_DIGEST_LENGTH])
{
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA256, key, keyLength);
    CCHmacUpdate(&cx, data, dataLength);
    CCHmacFinal(&cx, digest);
}


@implementation OKCrypto

+ (uint64_t)randomInt64
{
    uint8_t random[8];
    SecRandomCopyBytes(kSecRandomDefault, 8, random);
    
    uint64_t result;
    memcpy(&result, random, 8);
    return result;
}


+ (NSData*)HMACSHA256:(NSData*)data withKey:(NSString*)key
{
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    HMACSHA256([data bytes], [data length], [keyData bytes], [keyData length], digest);

    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}



+ (NSData*)AES256EncryptData:(NSData*)data withKey:(NSString*)key
{
    // GET KEY
	char keyPtr[kCCKeySizeAES256];
	bzero(keyPtr, sizeof(keyPtr));
    NSRange range = NSMakeRange(0, [key length]);
    [key getBytes:keyPtr maxLength:sizeof(keyPtr) usedLength:NULL encoding:NSUTF8StringEncoding options:0 range:range remainingRange:NULL];
	
    // ALLOCATE MEMORY
    size_t dataSize = [data length];
    size_t outputSize = dataSize + kCCBlockSizeAES128;
    size_t bufferSize = outputSize + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
    // GENERATE IV (initializing vector)
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, &buffer[0]);

    // ENCRYPT BUFFER
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          &buffer[0],
                                          [data bytes], dataSize, /* input */
                                          &buffer[kCCBlockSizeAES128], outputSize, /* output */
                                          &numBytesEncrypted);
    
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted+kCCBlockSizeAES128];
	}
    
    // error, free the buffer
    free(buffer);
	return nil;
}


+ (NSData*)AES256DecryptData:(NSData*)data withKey:(NSString *)key
{
    // GET KEY
	char keyPtr[kCCKeySizeAES256];
	bzero(keyPtr, sizeof(keyPtr));
    NSRange range = NSMakeRange(0, [key length]);
    [key getBytes:keyPtr maxLength:sizeof(keyPtr) usedLength:NULL encoding:NSUTF8StringEncoding options:0 range:range remainingRange:NULL];
    
	
    // ALLOCATE MEMORY
    size_t inputSize = [data length];
    size_t dataSize = inputSize-kCCBlockSizeAES128;
    size_t bufferSize = inputSize;
	void *buffer = malloc(bufferSize);

    // DECRYPT
    const void *bytes = [data bytes];
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          &bytes[0],
                                          &bytes[kCCBlockSizeAES128], dataSize, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}
	
    // error, free the buffer;
	free(buffer);
	return nil;
}


+ (NSData*)SHA256_AES256EncryptData:(NSData*)data withKey:(NSString *)key
{
    // Encrypt
    NSData *encrypted = [OKCrypto AES256EncryptData:data withKey:key];
    
    // Calculate digest
    NSData *digest = [OKCrypto HMACSHA256:encrypted withKey:key];
    
    // Build final
    NSUInteger resultLength = CC_SHA256_DIGEST_LENGTH + [encrypted length];
    NSMutableData *result = [NSMutableData dataWithCapacity:resultLength];
    [result appendData:digest];
    [result appendData:encrypted];
    
    return result;
}


+ (NSData*)SHA256_AES256DecryptData:(NSData*)data withKey:(NSString *)key
{
    if(!data)
        return nil;
    
    NSData *encrypted = [NSData dataWithBytes:[data bytes]+CC_SHA256_DIGEST_LENGTH length:[data length]-CC_SHA256_DIGEST_LENGTH];
    
    // Check hashs
    NSData *storedHash = [NSData dataWithBytes:[data bytes] length:CC_SHA256_DIGEST_LENGTH];
    NSData *hash = [OKCrypto HMACSHA256:encrypted withKey:key];

    if([storedHash isEqualToData:hash]) {
        return [OKCrypto AES256DecryptData:encrypted withKey:key];
    }else{
        NSLog(@"ERROR: The data was modified!");
        return nil;
    }
}

@end
