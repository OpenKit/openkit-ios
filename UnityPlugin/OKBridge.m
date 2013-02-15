//
//  OKBridge.m
//  OKBridge
//
//  Updated by Lou Zell on 2/14/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
//  Email feedback and suggestions to Lou at lzell11@gmail.com
//

#import "OKBridge.h"
#import "OK_SynthesizeSingleton.h"
#import "OKUnityHelper.h"
#include <regex.h>

#if TARGET_OS_IPHONE
#import "OKManager.h"
#endif

#if __has_feature(objc_arc)
#warning This file must not be compiled with ARC. Use the -fno-objc-arc flag.
#endif

#ifdef __cplusplus
extern "C" {
#endif
	typedef void* MonoDomain;
	typedef void* MonoAssembly;
	typedef void* MonoImage;
	typedef void* MonoClass;
	typedef void* MonoObject;
	typedef void* MonoMethodDesc;
	typedef void* MonoMethod;
	typedef void* MonoString;
	typedef int gboolean;
	typedef void* gpointer;
  
	MonoDomain *mono_domain_get();
	MonoAssembly *mono_domain_assembly_open(MonoDomain *domain, const char *assemblyName);
    MonoImage *mono_assembly_get_image(MonoAssembly *assembly);
	MonoMethodDesc *mono_method_desc_new(const char *methodString, gboolean useNamespace);
	MonoMethodDesc *mono_method_desc_free(MonoMethodDesc *desc);
	MonoMethod *mono_method_desc_search_in_image(MonoMethodDesc *methodDesc, MonoImage *image);
	MonoObject *mono_runtime_invoke(MonoMethod *method, void *obj, void **params, MonoObject **exc);
	MonoClass *mono_class_from_name(MonoImage *image, const char *namespaceString, const char *classnameString);
	MonoMethod *mono_class_get_methods(MonoClass*, gpointer* iter);
	MonoString *mono_string_new(MonoDomain *domain, const char *text);
	char* mono_method_get_name (MonoMethod *method);
#ifdef __cplusplus
}
#endif

static BOOL bridgeSetup = NO;

#pragma mark - OKBridge callback methods
static MonoMethod *mono_okbridgeDidInit;
static MonoMethod *mono_okbridgeLog;
static MonoMethod *mono_okbridgeLogError;


@implementation OKBridge
OK_SYNTHESIZE_SINGLETON_FOR_CLASS(OKBridge);

+ (void)UnityLog:(NSString *)str {
  if (!bridgeSetup) {
    return;
  }
  void *args[1] = {mono_string_new(mono_domain_get(), [[NSString stringWithFormat:@"OpenKit: %@",str] UTF8String])};
  mono_runtime_invoke(mono_okbridgeLog, NULL, args, NULL);
}

+ (void)UnityLogError:(NSString *)str {
  if (!bridgeSetup) {
      NSLog(@"OpenKit Native: Ignoring log request.  OKBridgeInit has not been called.");
    return;
  }
  void *args[1] = {mono_string_new(mono_domain_get(), [[NSString stringWithFormat:@"OpenKit: %@",str] UTF8String])};
  mono_runtime_invoke(mono_okbridgeLogError, NULL, args, NULL);
}

+ (void)checkOKBridgeSetup {
  if (!bridgeSetup) {
    [OKBridge UnityLogError:@"You must call OKBridgeInit before you can use OpenKit!"];
  }
}


#pragma mark - extern C functions
extern void OKBridgeInit(bool isEditor, const char *escapedCodeBase)
{
    if (bridgeSetup) {
        [OKBridge UnityLog:@"OKBridgeInit should only be called once!"];
        return;
    }
    NSString *assemblyPath = nil;
    MonoDomain *domain;
    MonoAssembly *monoAssembly;
    MonoImage *monoImage;

    if(isEditor) {
        // Pluck the file:// prefix and craziness after ScriptAssemblies/ off of crazyPath.
        int l = strlen(escapedCodeBase);    // Does not include null byte.
        regex_t preg1, preg2;
        regmatch_t match1, match2;
        regcomp(&preg1, "^file://", REG_EXTENDED);
        regcomp(&preg2, "Library/ScriptAssemblies/", REG_EXTENDED);

        if(regexec(&preg1, escapedCodeBase, 1, &match1, 0) == 0) {
            // front snip length
            int fsl = (int)match1.rm_eo - (int)match1.rm_so;      // end offset - start offset

            if(regexec(&preg2, escapedCodeBase, 1, &match2, 0) == 0) {
                // rear snip length
                int rsl = l - (int)match2.rm_eo;
                size_t buf_length = l + 1 - fsl - rsl;              // + 1 is for null byte
                char buf[buf_length];
                strlcpy(buf, escapedCodeBase + fsl, buf_length);
                assemblyPath = [NSString stringWithFormat:@"%s%s", buf, "Assembly-CSharp-firstpass.dll"];
            }
        }

        regfree(&preg1);
        regfree(&preg2);
        //NSLog(@"Assembly Path:%@", assemblyPath);
        assemblyPath = [assemblyPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        //NSLog(@"Assembly Path:%@", assemblyPath);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // Do sdk init here.
#if TARGET_OS_IPHONE
        [OKManager sharedManager];
#endif
    });

    if(!assemblyPath){
    assemblyPath = [[[NSBundle mainBundle] bundlePath]
                    stringByAppendingPathComponent:@"Data/Managed/Assembly-CSharp-firstpass.dll"];
    }
    domain = mono_domain_get();
    monoAssembly = mono_domain_assembly_open(domain, assemblyPath.UTF8String); 
    monoImage = mono_assembly_get_image(monoAssembly);

    // Format passed to mono_method_desc_new is "ClassName:StaticMethodName".
    mono_okbridgeLog =          mono_method_desc_search_in_image(mono_method_desc_new("OKBridge:OKBridgeLog", FALSE), monoImage);
    mono_okbridgeLogError =     mono_method_desc_search_in_image(mono_method_desc_new("OKBridge:OKBridgeLogError", FALSE), monoImage);
    mono_okbridgeDidInit =      mono_method_desc_search_in_image(mono_method_desc_new("OKBridge:OKBridgeDidInit", FALSE), monoImage);

    // Tell Unity we are done with init.
    bridgeSetup = YES;
    mono_runtime_invoke(mono_okbridgeDidInit, NULL, NULL, NULL);
}


void OKBridgeSetAppKey(const char *appKey)
{
    [OKBridge checkOKBridgeSetup];
    [OKBridge UnityLog:[NSString stringWithFormat:@"LZ: Setting key to %s", appKey]];
#if TARGET_OS_IPHONE
    [OKManager setApplicationID:[NSString stringWithUTF8String:appKey]];
#endif
}


@end


