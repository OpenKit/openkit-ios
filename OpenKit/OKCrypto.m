//
//  OKCrypto.m
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonKeyDerivation.h>

#import <Security/Security.h>
#import "OKCrypto.h"
#import "OKMacros.h"


@interface OKCrypto ()
{
    NSData *_cryptKey;
    NSData *_hmacKey;
}

@end


@implementation OKCrypto

+ (uint64_t)randomInt64
{
    uint8_t random[8];
    SecRandomCopyBytes(kSecRandomDefault, 8, random);
    
    uint64_t result;
    memcpy(&result, random, 8);
    return result;
}

+ (NSData*)derivateKey:(NSData*)key withString:(NSString*)string
{
    NSData *salt = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t derivedKey[kCCKeySizeAES256];
    
    CCKeyDerivationPBKDF(kCCPBKDF2,
                         [key bytes], [key length],
                         [salt bytes], [salt length],
                         kCCPRFHmacAlgSHA256, 5, derivedKey, kCCKeySizeAES256);
    
    
    return [NSData dataWithBytes:derivedKey length:kCCKeySizeAES256];
}


- (id)initWithMasterKey:(NSString*)masterKey
{
    NSParameterAssert(masterKey);
    
    self = [super init];
    if (self) {
        // Convert masterKey to NSData
        NSData *masterKeyData = [masterKey dataUsingEncoding:NSUTF8StringEncoding];
        
        // Derivate keys for
        _cryptKey = [OKCrypto derivateKey:masterKeyData withString:@"encrypt"];
        _hmacKey = [OKCrypto derivateKey:masterKeyData withString:@"hmac"];
        
        if([_cryptKey length] != kCCKeySizeAES256 || [_hmacKey length] != kCCKeySizeAES256) {
            OKLogErr(@"The key sizes are wrong.");
            return nil;
        }
    }
    return self;
}


- (NSData*)HMACSHA256:(NSData*)data
{
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, [_hmacKey bytes], [_hmacKey length], [data bytes], [data length], digest);
    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}


- (NSData*)AES128EncryptData:(NSData*)data
{
    // ALLOCATE MEMORY
    size_t dataSize = [data length];
    size_t outputSize = dataSize + kCCBlockSizeAES128;
    size_t bufferSize = outputSize + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
    // GENERATE IV (initializing vector)
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, &buffer[0]);

    // ENCRYPT BUFFER
	size_t numBytesEncrypted = 0;
	CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                     [_cryptKey bytes], [_cryptKey length], // key
                                     &buffer[0], // initialization vector
                                     [data bytes], dataSize, // data input
                                     &buffer[kCCBlockSizeAES128], outputSize, &numBytesEncrypted);
    
	if(status == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted+kCCBlockSizeAES128];
	}
    
    // error, free the buffer
    free(buffer);
	return nil;
}


- (NSData*)AES128DecryptData:(NSData*)data
{
    // ALLOCATE MEMORY
    size_t inputSize = [data length];
    size_t dataSize = inputSize-kCCBlockSizeAES128;
    size_t bufferSize = inputSize;
	void *buffer = malloc(bufferSize);

    // DECRYPT
    const void *bytes = [data bytes];
	size_t numBytesDecrypted = 0;
	CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                     [_cryptKey bytes], [_cryptKey length], // key
                                     &bytes[0], // initialization vector
                                     &bytes[kCCBlockSizeAES128], dataSize, // input data
                                     buffer, bufferSize, &numBytesDecrypted);
	
	if (status == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}
	
    // error, free the buffer;
	free(buffer);
	return nil;
}


- (NSData*)encryptData:(NSData*)data
{
    if(!data)
        return nil;
    
    // Encrypt
    NSData *encrypted = [self AES128EncryptData:data];
    
    // Calculate digest
    NSData *digest = [self HMACSHA256:encrypted];
    
    // Build final
    NSUInteger resultLength = [digest length] + [encrypted length];
    NSMutableData *result = [NSMutableData dataWithCapacity:resultLength];
    [result appendData:digest];
    [result appendData:encrypted];
    
    return result;
}


- (NSData*)decryptData:(NSData*)data
{
    if(!data && [data length]>CC_SHA256_DIGEST_LENGTH)
        return nil;
    
    NSData *encrypted = [NSData dataWithBytes:[data bytes]+CC_SHA256_DIGEST_LENGTH
                                       length:[data length]-CC_SHA256_DIGEST_LENGTH];
    
    // Check hashs
    NSData *storedHash = [NSData dataWithBytes:[data bytes] length:CC_SHA256_DIGEST_LENGTH];
    NSData *hash = [self HMACSHA256:encrypted];

    if([storedHash isEqualToData:hash]) {
        return [self AES128DecryptData:encrypted];
    }else{
        NSLog(@"ERROR: The data was modified!");
        return nil;
    }
}

@end
