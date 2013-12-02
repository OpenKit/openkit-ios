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

#define OK_SERVICE_NAME @"open_uuid"


@implementation OKUUIDPlugin

+ (OKAuthProvider*)sharedInstance
{
    OKAuthProvider *p = [OKAuthProvider providerByName:OK_SERVICE_NAME];
    if(p == nil) {
        p = [[OKUUIDPlugin alloc] init];
        [OKAuthProvider addProvider:p];
    }
    
    return p;
}


- (id)init
{
    self = [super initWithName:OK_SERVICE_NAME];
    self.priority = 1000;
    return self;
}


- (BOOL)isVisible
{
    return NO;
}


- (BOOL)isSessionOpen
{
    return YES;
}


- (BOOL)start
{
    return [self openSessionWithViewController:nil completion:nil];
}


- (BOOL)openSessionWithViewController:(UIViewController*)controller
                           completion:(void(^)(BOOL login, NSError *error))handler
{
    if(handler)
        handler(YES, nil);
    
    return YES;
}


- (void)getAuthRequestWithCompletion:(void(^)(OKAuthRequest *request, NSError *error))handler
{
    NSParameterAssert(handler);

    // get model
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.machine", model, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithCString:model encoding:NSUTF8StringEncoding];
    free(model);
    
    OKAuthRequest *request = [[OKAuthRequest alloc] initWithProvider:self
                                                              userID:[OKUtils vendorUUID]
                                                            userName:[[UIDevice currentDevice] name]
                                                        userImageURL:nil
                                                                 key:deviceModel
                                                                data:nil
                                                        publicKeyUrl:nil];
    
    handler(request, nil);
}

@end
