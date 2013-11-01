//
//  OKDBScore.m
//  OpenKit
//
//  Created by Manu Martinez-Almeida.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "FMDatabase.h"
#import "OKDBScore.h"
#import "OKMacros.h"
#import "OKFileUtil.h"

#define SCORES_CACHE_KEY @"OKLeaderboardScoresCache"


static NSString *const kOKDBScoreName = @"Scores";
static NSString *const kOKDBScoreVersion = @"1.0.4";
static NSString *const kOKDBScoreCreateSql =
    @"CREATE TABLE IF NOT EXISTS 'scores' "
    "("
    // default OpenKit DB columns
    "'row_id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "'submit_state' INTEGER, "
    "'modify_date' DATETIME, "
    "'client_created_at' DATETIME, "

    "'leaderboard_id' INTEGER, "
    "'value' BIGINT, "
    "'metadata' INTEGER, "
    "'display_string' VARCHAR(255) "
    "); ";



@implementation OKDBScore

+ (id)sharedConnection
{
    static dispatch_once_t pred;
    static id sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKDBScore alloc] initWithName:kOKDBScoreName
                                               createSql:kOKDBScoreCreateSql
                                                 version:kOKDBScoreVersion];
    });
    return sharedInstance;
}


- (OKScore*)lastScore
{
    __block OKScore *score = nil;
    [self executeQuery:@"SELECT * FROM scores ORDER BY modify_date DESC LIMIT 1"
                access:^(FMResultSet *rs)
     {
         if([rs next]) {
             NSDictionary *dict = [rs resultDictionary];
             score = [[OKScore alloc] initWithDictionary:dict];
             [score setDbConnection:self];
         }
     }];
    
    return score;
}


- (NSInteger)lastModifiedIndex
{
    __block NSInteger index = -1;
    [self executeQuery:@"SELECT * FROM scores ORDER BY modify_date DESC LIMIT 1"
                access:^(FMResultSet *rs)
     {
         if([rs next])
             index = [rs intForColumn:@"row_id"];
     }];
    
    return index;
}


- (BOOL)updateRow:(OKDBRow *)row
{
    OKScore *score = (OKScore*)row;
    
    NSString *updateSql = @"UPDATE scores SET submit_state=?, modify_date=?, leaderboard_id=?,\
    value=?, metadata=?, display_string=? WHERE row_id=?";
    
    return [self update:updateSql,
            @(score.submitState),
            score.modifyDate,
            @(score.leaderboardID),
            @(score.scoreValue),
            @(score.metadata),
            score.displayString,
            @(score.rowIndex)];
}


-(int64_t)insertRow:(OKDBRow*)row
{
    OKScore *score = (OKScore*)row;
    
    NSString *insertSql = @"INSERT INTO scores (submit_state, modify_date, client_created_at,\
    leaderboard_id, value, metadata, display_string) VALUES(?,?,?,?,?,?,?);";
    
    return [self insert:insertSql,
            @(score.submitState),
            score.modifyDate,
            score.createDate,
            @(score.leaderboardID),
            @(score.scoreValue),
            @(score.metadata),
            score.displayString];
}


- (BOOL)deleteRow:(OKDBRow *)row
{
    return [self update:@"DELETE FROM scores WHERE row_id=?", @(row.rowIndex)];
}


-(NSArray*)getAllScores
{
    return [self getScoresWithSQL:@"SELECT * FROM scores"];
}


-(NSArray*)getScoresForLeaderboardID:(NSInteger)lbID onlySubmitted:(BOOL)submittedOnly
{
    //OKLog(@"Getting cached scores for leaderboard ID: %d",leaderboardID);
    NSString *sql;
    
    if(submittedOnly)
        sql = [NSString stringWithFormat:@"SELECT * FROM scores WHERE leaderboard_id=%ld AND submit_state=1", (long)lbID];
    else
        sql = [NSString stringWithFormat:@"SELECT * FROM scores WHERE leaderboard_id=%ld", (long)lbID];
    
    return [self getScoresWithSQL:sql];
}


- (NSArray*)getUnsubmittedScores
{
    return [self getScoresWithSQL:@"SELECT * FROM scores WHERE submit_state=0"];
}


- (NSArray*)getScoresWithSQL:(NSString*)sql
{
    __block NSMutableArray *scoresArray = [[NSMutableArray alloc] init];
    [self executeQuery:sql access:^(FMResultSet *rs)
     {
         while([rs next]){
             NSDictionary *dict = [rs resultDictionary];
             OKScore *score = [[OKScore alloc] initWithDictionary:dict];
             [score setDbConnection:self];
             [scoresArray addObject:score];
         }
     }];
    
    return scoresArray;
}


- (void)clearSubmittedScores
{
    OKLogInfo(@"OKDBScore: Clear cached submitted scores");
    OKLogInfo(@"OKDBScore: Score cache before delete: %@", [self getAllScores]);
    
    [self update:@"DELETE FROM scores WHERE submit_state=1"];
}

@end
