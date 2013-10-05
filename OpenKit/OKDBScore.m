//
//  OKDBScore.m
//  OpenKit
//
//  Created by Suneet Shah on 7/26/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "FMDatabase.h"
#import "OKDBScore.h"
#import "OKMacros.h"
#import "OKUser.h"
#import <sqlite3.h>
#import "OKHelper.h"
#import "OKFileUtil.h"
#import "OKNetworker.h"

#define SCORES_CACHE_KEY @"OKLeaderboardScoresCache"


// Init cache DB
// DB Schema is:
// --------------------------------------------------------------------------------
// | integer | integer       | Bigint     | integer  | varchar(255)  | integer   |
// --------------------------------------------------------------------------------
// | id      | leaderboardID | scoreValue | metadata | displayString | submitted |

static NSString *const kOKDBScoreName = @"Scores";
static NSString *const kOKDBScoreVersion = @"1.0.3";
static NSString *const kOKDBScoreCreateSql =
    @"CREATE TABLE IF NOT EXISTS 'scores' "
    "("
    // default OpenKit DB columns
    "'row_id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "'submit_state' INTEGER, "
    "'modify_date' DATETIME, "

    "'leaderboard_id' INTEGER, "
    "'value' BIGINT, "
    "'metadata' INTEGER, "
    "'display_string' VARCHAR(255) "
    "); ";



@implementation OKDBScore

@synthesize previousSubmittedScore;

// Data Storage structure
// Array of cached scores
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


- (int)lastModifiedIndex
{
    __block int index = -1;
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
    
    NSString *updateSql = @"UPDATE scores SET submit_state=?, modify_date=?, leaderboard_id=?, value=?, metadata=?, display_string=? WHERE row_id=?";
    
    if(![self update:updateSql,
         [NSNumber numberWithInt:score.submitState],
         [score dbModifyDate],
         [NSNumber numberWithInt:score.leaderboardID],
         [NSNumber numberWithLong:score.scoreValue],
         [NSNumber numberWithInt:score.metadata],
         score.displayString,
         [NSNumber numberWithInt:score.rowIndex]]) {
        
        return NO;
    }
    return YES;
}


-(BOOL)insertRow:(OKDBRow*)row
{
    OKScore *score = (OKScore*)row;
    
    NSString *insertSql = @"INSERT INTO scores (submit_state, modify_date, leaderboard_id, value, metadata, display_string) VALUES(?,?,?,?,?,?);";
    
    if(![self update:insertSql,
         [NSNumber numberWithInt:score.submitState],
         [score dbModifyDate],
         [NSNumber numberWithInt:score.leaderboardID],
         [NSNumber numberWithLong:score.scoreValue],
         [NSNumber numberWithInt:score.metadata],
         score.displayString]) {
        
        return NO;
    }
    return YES;
}


- (BOOL)deleteRow:(OKDBRow *)row
{
    return [self update:@"DELETE FROM scores WHERE row_id=?", [NSNumber numberWithInt:row.rowIndex]];
}


-(NSArray*)getAllScores
{
    return [self getScoresWithSQL:@"SELECT * FROM scores"];
}


-(NSArray*)getScoresForLeaderboardID:(int)leaderboardID andOnlyGetSubmittedScores:(BOOL)submittedOnly
{
    //OKLog(@"Getting cached scores for leaderboard ID: %d",leaderboardID);
    NSString *queryString;
    
    if(submittedOnly)
        queryString = [NSString stringWithFormat:@"SELECT * FROM scores WHERE leaderboard_id=%d AND submit_state=1", leaderboardID];
    else
        queryString = [NSString stringWithFormat:@"SELECT * FROM scores WHERE leaderboard_id=%d", leaderboardID];
    
    return [self getScoresWithSQL:queryString];
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
    OKLog(@"Clear cached submitted scores");
    OKLog(@"Score cache before delete: %@", [self getAllScores]);
    
    [self update:@"DELETE FROM scores WHERE submit_state=1"];
}

@end
