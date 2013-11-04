//
//  OKMacros.h
//  OKClient
//
//  Created by Louis Zell on 1/27/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#ifndef OKClient_OKMacros_h
#define OKClient_OKMacros_h


#pragma mark - Logging

#define OK_VERBOSE_LOGGING 0
#if OK_VERBOSE_LOGGING

#define OKLog(s, ...)     NSLog(@"OpenKit: %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#define OKLogErr(s, ...)  NSLog(@"OpenKit:ERROR: %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#if defined(DEBUG)
    #define OKLogInfo(s, ...) NSLog(@"OpenKit:Info: %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
    #define OKLogInfo(...)    {}
#endif

#else

#define OKLog(s, ...)     fprintf(stdout, "OpenKit: %s\n", [[NSString stringWithFormat:s, ##__VA_ARGS__] UTF8String] )
#define OKLogErr(s, ...)  fprintf(stderr, "OpenKit:ERROR: %s\n", [[NSString stringWithFormat:s, ##__VA_ARGS__] UTF8String] )
#if defined(DEBUG)
    #define OKLogInfo(s, ...) fprintf(stdout, "OpenKit:Info: %s\n", [[NSString stringWithFormat:s, ##__VA_ARGS__] UTF8String] )
#else
    #define OKLogInfo(...)    {}
#endif

#endif


#ifdef  DEBUG
#define OKBridgeLog( s, ... ) NSLog(@"OKBridgeIOS: %@", [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define OKBridgeLog( s, ...) {} while (0)
#endif


#pragma mark - Exceptions

#define OK_RAISE(name, ...) {\
    NSString *str = [NSString stringWithFormat:__VA_ARGS__]; \
    NSLog(@"Raising %@: %@", name, str); \
    [NSException raise:name format:str]; \
}


#pragma mark - Objetive-C Safety

#define OK_NO_NIL(__OBJ__) ((__OBJ__)==nil ? [NSNull null] : (__OBJ__))
#define DYNAMIC_CAST(__CLASS__, __OBJ__) ((__CLASS__*)([__OBJ__ isKindOfClass:[__CLASS__ class]] ? __OBJ__ : nil))


#pragma mark - System Versioning

#define OK_SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define OK_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define OK_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define OK_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define OK_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif
