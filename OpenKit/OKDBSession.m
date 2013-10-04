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



static NSString *const kOKDBSessionName = @"Session";
static NSString *const kOKDBSessionVersion = @"0.0.39";
static NSString *const kOKDBSessionCreateSql =
    @"CREATE TABLE IF NOT EXISTS 'sessions' "
    "("
    // default OpenKit DB columns
    "'id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "'submit_state' INTEGER, "
    "'modify_date' DATETIME, "

    // rest columns
    "'token' VARCHAR(255), "
    "'fb_id' VARCHAR(40), "
    "'fb_active' BOOLEAN, "
    "'google_id' VARCHAR(40), "
    "'google_active' BOOLEAN, "
    "'custom_id' VARCHAR(40), "
    "'custom_active' BOOLEAN, "
    "'ok_id' VARCHAR(40), "
    "'ok_active' BOOLEAN, "
    "'push_token' VARCHAR(64) "
    "); ";


@implementation OKDBSession

- (id)init
{
    self = [super initWithName:kOKDBSessionName
                     createSql:kOKDBSessionCreateSql
                       version:kOKDBSessionVersion];

    return self;
}


- (OKSession*)lastSession
{
    __block OKSession *session = nil;
    [self executeQuery:@"SELECT * FROM sessions ORDER BY modify_date DESC LIMIT 1"
                access:^(FMResultSet *rs)
    {
        if([rs next]) {
            NSDictionary *dict = [rs resultDictionary];
            session = [[OKSession alloc] initWithDictionary:dict];
        }
    }];

    return session;
}


- (BOOL)insertRow:(OKDBRow*)row
{
    OKSession *session = (OKSession*)row;
    NSString *insertSql = @"INSERT INTO sessions (submit_state, modify_date, token, fb_id, google_id, custom_id, ok_id, push_token) VALUES (?,?,?,?,?,?,?,?)";
    
    if(![self update:insertSql,
         session.submitState,
         session.dbModifyDate,
         session.token,
         session.fbId,
         session.googleId,
         session.customId,
         session.okId,
         session.pushToken]) {
        
        return NO;
    }
    
    return YES;
}


- (BOOL)updateRow:(OKDBRow *)row
{
    OKSession *session = (OKSession*)row;
    
    NSString *updateSql = @"UPDATE sessions submit_state='?', modify_date='?', token='?', fb_id='?', google_id='?', custom_id='?', ok_id='?', push_token='?' WHERE id = ?";
    
    if(![self update:updateSql,
         session.submitState,
         session.dbModifyDate,
         session.token,
         session.fbId,
         session.googleId,
         session.customId,
         session.okId,
         session.pushToken,
         session.rowIndex]) {
        
        return NO;
    }
    return YES;
}


- (int)lastModifiedIndex
{
    __block int index = -1;
    [self executeQuery:@"SELECT * FROM sessions ORDER BY modify_date DESC LIMIT 1"
                access:^(FMResultSet *rs)
     {
         if([rs next])
             index = [rs intForColumn:@"id"];
     }];
    
    return index;
}

@end
