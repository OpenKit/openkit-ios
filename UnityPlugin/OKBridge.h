//
//  OKBridge.h
//  OKBridge
//
//  Updated by Lou Zell on 2/14/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
//  Email feedback and suggestions to Lou at lzell11@gmail.com
//

#import <Foundation/Foundation.h>


@interface OKBridge : NSObject

+ (OKBridge *)sharedOKBridge;
+ (void)UnityLog:(NSString *)str;
+ (void)UnityLogError:(NSString *)str;

@end

extern void OKBridgeInit(bool isEditor, const char *escapedCodeBase);
extern void OKBridgeSetAppKey(const char *appKey);
