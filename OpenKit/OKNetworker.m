//  Created by Manuel Martinez-Almeida and Lou Zell
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKNetworker.h"
#import "OKManager.h"
#import "OKUtils.h"
#import "OKMacros.h"
#import "OKError.h"
#import "OKPrivate.h"
#import "OKRequest.h"

#define OK_UNSUBSCRIBED_USER_ERROR_CODE 410


typedef void (^OKNetworkerBlock)(id responseObject, NSError * error);
static NSString *OK_SERVER_API_VERSION = @"v1";


@implementation OKNetworker

+ (OKRequest*)newRequest
{
    OKClient *client = [[OKManager sharedManager] client];
    OKLocalUser *user = [OKLocalUser currentUser];
    return [[OKRequest alloc] initWithClient:client user:user];
}


+ (void)getFromPath:(NSString *)path
         parameters:(NSDictionary *)params
         completion:(void (^)(OKResponse *response))handler
{
    [[self newRequest] get:path
               queryParams:params
                  complete:handler];
}


+ (void)postToPath:(NSString *)path
        parameters:(NSDictionary *)params
        completion:(void (^)(OKResponse *response))handler
{
    [[self newRequest] post:path
                  reqParams:params
                   complete:handler];
}


+ (void)putToPath:(NSString *)path
       parameters:(NSDictionary *)params
       completion:(void (^)(OKResponse *response))handler
{
    [[self newRequest] put:path
                 reqParams:params
                  complete:handler];

}

@end
