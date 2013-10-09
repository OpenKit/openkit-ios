//
//  OKSessionDb.m
//  OpenKit
//
//  Created by Louis Zell on 8/22/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "FMDatabase.h"
#import "OKDBSession.h"
#import "OKMacros.h"
#import "OKNetworker.h"
#import "OKUtils.h"

// TODO: Remove this dependency.
#import "OKUser.h"


static NSString *const kOKDBSessionName = @"Session";
static NSString *const kOKDBSessionVersion = @"0.0.48";
static NSString *const kOKDBSessionCreateSql =
    @"CREATE TABLE IF NOT EXISTS 'sessions' "
    "("
    // default OpenKit DB columns
    "'row_id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "'submit_state' INTEGER, "
    "'modify_date' DATETIME, "
    "'client_created_at' DATETIME, "  

    // rest columns
    "'uuid' VARCHAR(255), "
    "'fb_id' VARCHAR(40), "
    "'fb_active' BOOLEAN, "
    "'google_id' VARCHAR(40), "
    "'custom_id' VARCHAR(40), "
    "'ok_id' VARCHAR(40), "
    "'push_token' VARCHAR(64) "
    "); ";


@implementation OKDBSession

+ (id)sharedConnection
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKDBSession alloc] initWithName:kOKDBSessionName
                                                 createSql:kOKDBSessionCreateSql
                                                   version:kOKDBSessionVersion];
    });
    return sharedInstance;
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
            [session setDbConnection:self];
        }
    }];

    return session;
}


- (int)insertRow:(OKDBRow*)row
{
    OKSession *session = (OKSession*)row;
    NSString *insertSql = @"INSERT INTO sessions (submit_state, modify_date, client_created_at, uuid, fb_id, google_id, custom_id, ok_id, push_token) VALUES (?,?,?,?,?,?,?,?,?)";
    
    return [self insert:insertSql,
            [NSNumber numberWithInt:session.submitState],
            session.dbModifyDate,
            [session dbCreateDate],
            session.token,
            session.fbId,
            session.googleId,
            session.customId,
            session.okId,
            session.pushToken];
}


- (BOOL)updateRow:(OKDBRow *)row
{
    OKSession *session = (OKSession*)row;
    
    NSString *updateSql = @"UPDATE sessions SET submit_state=?, modify_date=?, uuid=?, fb_id=?, google_id=?, custom_id=?, ok_id=?, push_token=? WHERE row_id=?";
    
    return [self update:updateSql,
            [NSNumber numberWithInt:session.submitState],
            session.dbModifyDate,
            session.token,
            session.fbId,
            session.googleId,
            session.customId,
            session.okId,
            session.pushToken,
            [NSNumber numberWithInt:session.rowIndex]];
}


- (BOOL)deleteRow:(OKDBRow *)row
{
    return [self update:@"DELETE FROM sessions WHERE row_id=?", [NSNumber numberWithInt:row.rowIndex]];
}


- (int)lastModifiedIndex
{
    __block int index = -1;
    [self executeQuery:@"SELECT * FROM sessions ORDER BY modify_date DESC LIMIT 1"
                access:^(FMResultSet *rs)
     {
         if([rs next])
             index = [rs intForColumn:@"row_id"];
     }];
    
    return index;
}

@end
