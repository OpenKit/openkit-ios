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


- (BOOL)configWithDictionary:(NSDictionary*)dict
{
    self.rowIndex   = [OKHelper getIntFrom:dict key:@"row_id"];
    self.modifyDate = [OKHelper getNSDateFrom:dict key:@"modify_date"];
    self.createDate = [OKHelper getNSDateFrom:dict key:@"client_created_at"];
    
    self.token      = [OKHelper getNSStringFrom:dict key:@"uuid"];
    self.fbId       = [OKHelper getNSStringFrom:dict key:@"fb_id"];
    self.googleId   = [OKHelper getNSStringFrom:dict key:@"google_id"];
    self.customId   = [OKHelper getNSStringFrom:dict key:@"custom_id"];
    self.pushToken  = [OKHelper getNSStringFrom:dict key:@"push_token"];
    self.okId       = [OKHelper getNSStringFrom:dict key:@"ok_id"];
    
    return YES;
}


- (void)migrateUser
{
    OKUser *user = [OKLocalUser currentUser];
    if (user) {
        self.okId = [user userID];
        self.fbId = [user userIDForService:@"facebook"];
        self.customId = [user userIDForService:@"custom"];
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
    NSAssert(self.token, @"Token can not be nil");
    NSAssert(self.createDate, @"Creation date can not be nil.");
    
    return @{@"uuid": self.token,
             @"client_created_at": self.createDate,
             @"fb_id": OK_NO_NIL(self.fbId),
             @"google_id": OK_NO_NIL(self.googleId),
             @"custom_id": OK_NO_NIL(self.customId),
             @"push_token": OK_NO_NIL(self.pushToken),
             @"ok_id": OK_NO_NIL(self.okId)};
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

+ (void)resolveUnsubmittedSession
{
    // Removing
    NSArray *sessions = [[OKDBSession sharedConnection] getUnsubmittedSessions];
    
    for(OKSession *session in sessions)
        [OKSession resolveSession:session withCompletion:nil];
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
    
    // We try to send to the backend
    if([session submitState] == kOKNotSubmitted) {
        [session setSubmitState:kOKSubmitting];
        [OKSession resolveSession:session withCompletion:nil];
    }
}


+ (void)resolveSession:(OKSession*)session withCompletion:(void (^)(NSError *error))handler
{
    [OKNetworker postToPath:@"/client_sessions"
                 parameters:[session JSONDictionary]
                 completion:^(id responseObject, NSError *error)
    {
        if (!error)
            [session setSubmitState:kOKSubmitted];
        else
            [session setSubmitState:kOKNotSubmitted];
        
        [session syncWithDB];
    }];
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
        OKLogInfo(@"No previous session found. Creating new row with new %@.", getName);
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
            OKLogInfo(@"Prev and new vals do not match. Creating new row with new %@.", getName);
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
