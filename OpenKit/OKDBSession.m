//
//  OKSessionDb.m
//  OpenKit
//
//  Created by Louis Zell on 8/22/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKDBSession.h"
#import "OKMacros.h"
#import "OKNetworker.h"
#import "OKUtils.h"

// TODO: Remove this dependency.
#import "OKUser.h"



static NSString *const kOKSessionTableVersion = @"0.0.38";
static NSString *const kOKSessionTableCreateSql =
    @"CREATE TABLE 'sessions' "
    "("
    "'id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL , "
    "'uuid' VARCHAR(255) , "
    "'fb_id' VARCHAR(40), "
    "'fb_active' BOOLEAN, "
    "'google_id' VARCHAR(40), "
    "'google_active' BOOLEAN, "
    "'custom_id' VARCHAR(40), "
    "'custom_active' BOOLEAN, "
    "'ok_id' VARCHAR(40), "
    "'ok_active' BOOLEAN, "
    "'push_token' VARCHAR(64), "
    "'client_created_at' DATETIME"
    ")"
    "\n"        // Important.
    "CREATE TABLE 'submissions' "
    "("
    "'id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL , "
    "'payload' TEXT , "
    "'status' INTEGER "
    "); ";


@implementation OKDBSession

+ (id)sharedConnection
{
    static dispatch_once_t pred;
    static OKDBSession *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKDBSession alloc] init];
    });
    return sharedInstance;
}


- (id)init
{
    self = [super initWithName:@"Session"
                     createSql:kOKSessionTableCreateSql
                       version:kOKSessionTableVersion];

    return self;
}


- (OKSession*)lastSession
{
    __block OKSession *session = nil;
    [[OKDBSession sharedConnection] executeQuery:@"select * from sessions order by client_created_at DESC limit 1"
                                          access:^(FMResultSet *rs)
    {
        if([rs next]) {
            NSDictionary *dict = [rs resultDictionary];
            session = [[OKSession alloc] initWithDictionary:dict];
        }
    }];

    return session;
}


- (id)insertRow:(OKDBRow*)row
{
    OKSession *session = (OKSession*)row;
    
    NSString *insertSql = @"insert into sessions (uuid, fb_id, google_id, custom_id, ok_id, push_token, client_created_at) values (?, ?, ?, ?, ?, ?, ?)";
    
    BOOL success = [self update:insertSql,
                    session.uuid,
                    session.fbId,
                    session.googleId,
                    session.customId,
                    session.okId,
                    session.pushToken,
                    session.dbModifyDate];
    
    if(!success) {
        OKLogErr(@"Could not create new session.");
        return nil;
    }
    
    
    // get last session
    session = [self lastSession];
    return session;
}


- (id)updateRow:(OKDBRow *)row
{
    OKSession *session = (OKSession*)row;
    
    NSString *updateSql = @"update sessions uuid='?', fb_id='?', google_id='?', custom_id='?', ok_id='?', push_token='?', client_created_at='?' WHERE ID = ?";
    
    BOOL success = [self update:updateSql,
                    session.uuid,
                    session.fbId,
                    session.googleId,
                    session.customId,
                    session.okId,
                    session.pushToken,
                    session.dbModifyDate,
                    
                    session.rowIndex];
    
    if(!success) {
        OKLogErr(@"Could not create new session.");
        return nil;
    }

    return session;
}

@end
