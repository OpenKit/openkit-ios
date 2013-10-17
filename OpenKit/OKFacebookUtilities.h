//
//  OKFacebookUtilities.h
//  OKClient
//
//  Created by Suneet Shah on 1/3/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OKAuth.h"


@class OKUser;
@interface OKFacebookPlugin : OKAuthProvider

// Other FB helper methods
+ (void)handleErrorLoggingIntoFacebookAndShowAlertIfNecessary:(NSError *)error;

// FB Invites
+ (void)sendFacebookRequest;

@end
