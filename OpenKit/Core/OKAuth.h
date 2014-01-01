//
//  OKAuth.h
//  OpenKit
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>


@class OKAuthRequest;
@class OKAuthProfile;
@class OKAuthProvider;
@protocol OKAuthPluginProtocol;


@interface OKAuthProvider : NSObject

@property(nonatomic, readwrite) Class<OKAuthPluginProtocol> pluginClass;
@property(nonatomic, readwrite) NSInteger priority;

+ (void)addProvider:(OKAuthProvider*)provider;
+ (OKAuthProvider*)providerByName:(NSString*)name;
+ (NSArray*)getProviders;

@end


@interface OKAuthRequest : NSObject

@property(nonatomic, readonly) OKAuthProvider *provider;
@property(nonatomic, readonly) NSString *userID;
@property(nonatomic, readonly) NSString *userName;
@property(nonatomic, readonly) NSString *userImageUrl;

- (id)initWithProvider:(OKAuthProvider*)provider
                userID:(NSString*)userid
              userName:(NSString*)username
          userImageURL:(NSString*)imageUrl
                 token:(NSString*)token;


- (id)initWithProvider:(OKAuthProvider*)provider
                userID:(NSString*)userid
              userName:(NSString*)username
          userImageURL:(NSString*)imageUrl
                   key:(NSString*)key
                  data:(NSString*)data
          publicKeyUrl:(NSString*)url;


- (NSDictionary*)JSONDictionary;

@end

