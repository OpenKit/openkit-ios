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
static NSString *const kOKDBSessionVersion = @"0.0.49";
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
    NSString *insertSql = @"INSERT INTO sessions (submit_state, modify_date, client_created_at, \
    uuid, fb_id, google_id, custom_id, ok_id, push_token) VALUES (?,?,?,?,?,?,?,?,?)";
    
    return [self insert:insertSql,
            @(session.submitState),
            session.modifyDate,
            session.createDate,
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
    
    NSString *updateSql = @"UPDATE sessions SET submit_state=?, modify_date=?, uuid=?, fb_id=?, \
    google_id=?, custom_id=?, ok_id=?, push_token=? WHERE row_id=?";
    
    return [self update:updateSql,
            @(session.submitState),
            session.modifyDate,
            session.token,
            session.fbId,
            session.googleId,
            session.customId,
            session.okId,
            session.pushToken,
            @(session.rowIndex)];
}


- (BOOL)deleteRow:(OKDBRow *)row
{
    return [self update:@"DELETE FROM sessions WHERE row_id=?", @(row.rowIndex)];
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


- (NSArray*)getUnsubmittedSessions
{
    return [self getScoresWithSQL:@"SELECT * FROM sessions WHERE submit_state=0"];
}


- (NSArray*)getScoresWithSQL:(NSString*)sql
{
    __block NSMutableArray *sessionsArray = [[NSMutableArray alloc] init];
    [self executeQuery:sql access:^(FMResultSet *rs)
     {
         while([rs next]){
             NSDictionary *dict = [rs resultDictionary];
             OKSession *score = [[OKSession alloc] initWithDictionary:dict];
             [score setDbConnection:self];
             [sessionsArray addObject:score];
         }
     }];
    
    return sessionsArray;
}

@end
