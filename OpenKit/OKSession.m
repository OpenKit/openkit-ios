//
//  OKSessionDb.m
//  OpenKit
//
//  Created by Louis Zell on 8/22/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKSession.h"
#import "OKDBSession.h"
#import "OKUser.h"
#import "OKMacros.h"
#import "OKNetworker.h"
#import "OKHelper.h"
#import "OKUtils.h"


OKSession *__currentSession = nil;

@implementation OKSession

- (id)init
{
    self = [super init];
    if (self) {
        self.token = [OKUtils createUUID];
    }
    return self;
}


- (id)initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        [self configWithDictionary:dict];
    }
    return self;
}


- (void)configWithDictionary:(NSDictionary*)dict
{
    self.rowIndex   = [OKHelper getIntSafeForKey:@"row_id" fromJSONDictionary:dict];
    self.modifyDate = [OKHelper getNSDateSafeForKey:@"modify_date" fromJSONDictionary:dict];
    self.createDate = [OKHelper getNSDateSafeForKey:@"client_created_at" fromJSONDictionary:dict];
    
    self.token      = [OKHelper getNSStringSafeForKey:@"uuid" fromJSONDictionary:dict];
    self.fbId       = [OKHelper getNSStringSafeForKey:@"fb_id" fromJSONDictionary:dict];
    self.googleId   = [OKHelper getNSStringSafeForKey:@"google_id" fromJSONDictionary:dict];
    self.customId   = [OKHelper getNSStringSafeForKey:@"custom_id" fromJSONDictionary:dict];
    self.pushToken  = [OKHelper getNSStringSafeForKey:@"push_token" fromJSONDictionary:dict];
    self.okId       = [OKHelper getNSStringSafeForKey:@"ok_id" fromJSONDictionary:dict];
}


- (void)migrateUser
{
    OKUser *user = [OKUser currentUser];
    if (user) {
        self.okId = user.OKUserID ? [user.OKUserID stringValue] : nil;
        self.fbId = user.fbUserID ? user.fbUserID : nil;
        self.customId = user.customID ? user.customID : nil;
    }
}


- (OKSession*)getNewSession
{
    OKSession *session = [[OKSession alloc] init];
    session.fbId = self.fbId;
    session.googleId = self.googleId;
    session.customId = self.customId;
    session.pushToken = self.pushToken;
    session.okId = self.okId;
    
    return session;
}


- (NSDictionary*)JSONDictionary
{
    return [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            self.token, @"uuid",
            self.fbId ? self.fbId : [NSNull null], @"fb_id",
            self.googleId ? self.googleId : [NSNull null], @"google_id",
            self.customId ? self.customId : [NSNull null], @"custom_id",
            self.pushToken ? self.pushToken : [NSNull null], @"push_token",
            self.okId ? self.okId : [NSNull null], @"ok_id",
            [self dbCreateDate], @"client_created_at",
            nil];
}


#pragma mark - Class methods

+ (void)activate
{
    if ([OKSession currentSession] == nil) {
        OKSession *newSession = [[OKSession alloc] init];
        [newSession migrateUser];
        [[OKDBSession sharedConnection] syncRow:newSession];
    }
}


// Session updates are always relayed to the backend.  It is the backend's job to
// figure out how to stitch sessions together into single OKUser's attributes, e.g
// facebook id, push tokens, google id, etc.
+ (void)submitSession:(OKSession*)session
{
    // Setting the DB connection and inserting it
    [session setDbConnection:[OKDBSession sharedConnection]];
    [session syncWithDB];
    
    __currentSession = session;
    //OKLogInfo(@"Current OK Session: rowId: %i, uuid: %@, okId: %@, fbId: %@, pushToken: %@, clientCreatedAt: %@", row.rowId, row.uuid, row.okId, row.fbId, row.pushToken, row.clientCreatedAt);

    
    // We try to send to the backend
    if([session submitState] == kOKNotSubmitted) {
        [session setSubmitState:kOKSubmitting];
        
        [OKNetworker postToPath:@"/client_sessions"
                     parameters:[session JSONDictionary]
                        handler:^(id responseObject, NSError *error) {
            if (!error)
                [session setSubmitState:kOKSubmitted];
            else
                [session setSubmitState:kOKNotSubmitted];
            
            [session syncWithDB];
        }];
    }
}


+ (OKSession*)currentSession
{
    if(!__currentSession)
        __currentSession = [[OKDBSession sharedConnection] lastSession];
    
    return __currentSession;
}


+ (void)registerPush:(NSString *)aPushToken
{
    [OKSession newVal:aPushToken getSelName:@"pushToken" setSelName:@"setPushToken:"];
}


// See comment on -registerPush.
// DRY this.
+ (void)loginFB:(NSString *)aFacebookId
{
    [OKSession newVal:aFacebookId getSelName:@"fbId" setSelName:@"setFbId:"];
}

       
+ (void)logoutFB
{
    [OKSession newVal:nil getSelName:@"fbId" setSelName:@"setFbId:"];
}


+ (void)loginGoogle:(NSString *)aGoogleId
{
    [OKSession newVal:aGoogleId getSelName:@"googleId" setSelName:@"setGoogleId:"];
}

+ (void)logoutGoogle
{
    [OKSession newVal:nil getSelName:@"googleId" setSelName:@"setGoogleId:"];
}

+ (void)loginCustom:(NSString *)aCustomId
{

}

+ (void)logoutCustom
{

}


// Temporary.
// See comment on -registerPush.
// DRY this.
+ (void)loginOpenKit:(NSString *)anOpenKitId
{
    [OKSession newVal:anOpenKitId getSelName:@"okId" setSelName:@"setOkId:"];
}


+ (void)logoutOpenKit
{
    
}

// The logic here works like this:
// If there is no session, create a new session and set push token.
// If there is a previous session but no push token, create new row with same uuid and set token.
// If there is a previous session and push token, and the previous token matches next, do nothing.
// If there is a previous session and push token, and the previous token doesn't match next, create new row with _new_ uuid and set token.
+ (void)newVal:(NSString *)newVal getSelName:(NSString *)getName setSelName:(NSString *)setName
{
    OKSession *currentSession = [OKSession currentSession];
    OKSession *newSession = nil;

    
    if (currentSession == nil) {
        OKLogInfo(@"No previous session found. Creating new row with new uuid and new %@.", getName);
        newSession = [[OKSession alloc] init];
        [newSession migrateUser];
        
    } else if(getName)
    {
        SEL getSelector = NSSelectorFromString(getName);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSString *prevVal = [currentSession performSelector:getSelector];
#pragma clang diagnostic pop
        
        //OKLogInfo(@"Row exists but no val, creating new row with same uuid and new %@.", getName);

        if (![prevVal isEqualToString:newVal]) {
            OKLogInfo(@"Prev and new vals do not match. Creating new row with new uuid and new %@.", getName);
            newSession = [currentSession getNewSession];
            
        } else {
            OKLogInfo(@"%@ is already up to date in db.  Not updating.", getName);
        }
    }
    
    if(setName) {
        SEL setSelector = NSSelectorFromString(setName);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [newSession performSelector:setSelector withObject:newVal];
#pragma clang diagnostic pop
    }
    
    [OKSession submitSession:newSession];
}


@end
