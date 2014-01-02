//
//  OKFacebookUtilities.m
//  OKClient
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#include <sys/sysctl.h>
#import "OKUUIDPlugin.h"
#import "OKUtils.h"


@implementation OKUUIDPlugin

+ (NSString*)serviceName
{
    return @"open_uuid";
}

+ (BOOL)isVisible
{
    return NO;
}


+ (BOOL)isSessionOpen
{
    return YES;
}


+ (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler
{
    if(handler)
        handler(YES, nil);
    
    return YES;
}


+ (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSParameterAssert(handler);

    // get model
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    
    OKAuthRequest *request = [[OKAuthRequest alloc] initWithProvider:[self sharedInstance]
                                                              userID:[OKUtils vendorUUID]
                                                            userName:[[UIDevice currentDevice] name]
                                                        userImageURL:nil
                                                                 key:deviceModel
                                                                data:nil
                                                        publicKeyUrl:nil];

    NSError *error = nil;
    if(!request) {
        // REVIEW
        error = nil;
    }

    handler(request, error);
}

@end
