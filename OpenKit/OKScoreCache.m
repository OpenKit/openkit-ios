//
//  OKScoreCache.m
//  OpenKit
//
//  Created by Suneet Shah on 7/26/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKScoreCache.h"
#import "OKMacros.h"
#import "OKUser.h"
#import <sqlite3.h>
#import "OKHelper.h"

#define SCORES_CACHE_KEY @"OKLeaderboardScoresCache"

@implementation OKScoreCache
{
    sqlite3 *_database;
}

static sqlite3_stmt *insertScoreStatement = nil;
static sqlite3_stmt *deleteScoreStatement = nil;

+ (OKScoreCache*)sharedCache
{
    static dispatch_once_t pred;
    static OKScoreCache *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[OKScoreCache alloc] init];
    });
    return sharedInstance;
}

// Data Storage structure
// Array of cached scores

- (id)init
{
    self = [super init];
    if (self) {
        //init code
        [self initDB];
    }
    return self;
}

-(NSString*)dbPath
{
    NSString *docsDir = [OKHelper getPathToDocsDirectory];
    NSString *dbFilePath = [docsDir stringByAppendingPathComponent:@"okCache.db"];
    return dbFilePath;
}

// Init cache DB
// DB Schema is:
// --------------------------------------------------------------------------------
// | integer | integer       | Bigint     | integer  | varchar(255)  | integer   |
// --------------------------------------------------------------------------------
// | id      | leaderboardID | scoreValue | metadata | displayString | submitted |

-(void)initDB
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if([fm fileExistsAtPath:[self dbPath]] == NO)
    {
        OKLog(@"Creating cache DB file");
    } else {
        OKLog(@"Cache DB file found");
    }
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_database) == SQLITE_OK) {
        char *errorMsg;
        const char *dbInitStatement = "CREATE TABLE IF NOT EXISTS OKCACHE(id INTEGER PRIMARY KEY AUTOINCREMENT, leaderboardID INTEGER, scoreValue BIGINT, metadata INTEGER, displayString VARCHAR(255), submitted BOOLEAN);";
        
        if(sqlite3_exec(_database, dbInitStatement, NULL, NULL, &errorMsg) != SQLITE_OK) {
            OKLog(@"Failed to create cache table");
        } else {
            OKLog(@"Created or found cache table");
        }
        
        sqlite3_close(_database);
    } else {
        OKLog(@"Failed to open/create database");
    }
}


-(void)storeScore:(OKScore*)score
{
    [self storeScore:score wasScoreSubmitted:NO];
}

-(void)storeScore:(OKScore*)score wasScoreSubmitted:(BOOL)submitted
{
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_database) == SQLITE_OK) {
        
        // Setup the SQL Statement
        if(insertScoreStatement == nil) {
            OKLog(@"Preparing statement for cache score");
            const char *insertSQL = "INSERT INTO OKCACHE(leaderboardID,scoreValue,metadata,displayString,submitted) VALUES(?,?,?,?,?);";
            
            if(sqlite3_prepare_v2(_database, insertSQL, -1, &insertScoreStatement, NULL) != SQLITE_OK) {
                OKLog(@"Failed to prepare score insert statement with message: '%s'", sqlite3_errmsg(_database));
                return;
            }
        }
        
        // Bind the score values to the statement
        sqlite3_bind_int(insertScoreStatement, 1, [score OKLeaderboardID]);
        sqlite3_bind_int64(insertScoreStatement, 2, [score scoreValue]);
        sqlite3_bind_int(insertScoreStatement, 3, [score metadata]);
        
        if([score displayString]) {
            sqlite3_bind_text(insertScoreStatement, 4, [[score displayString] UTF8String], -1, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_null(insertScoreStatement, 4);
        }
        sqlite3_bind_int(insertScoreStatement, 5, (int)submitted);
        
        //Execute the SQL statement
        if(sqlite3_step(insertScoreStatement) == SQLITE_DONE) {
            OKLog(@"Cached score with value: %lld & leaderboard id: %d",[score scoreValue], [score OKLeaderboardID]);
        } else {
            OKLog(@"Failed to store score in cache wihth error message: %s",sqlite3_errmsg(_database));
        }
        
        sqlite3_reset(insertScoreStatement);
        sqlite3_clear_bindings(insertScoreStatement);
        sqlite3_close(_database);
        
    } else {
        OKLog(@"Could not open cache DB insertScore");
    }
}

-(void)removeScore:(OKScore*)score
{
    if(![score OKScoreID]) {
        OKLog(@"Tried to remove a score without a scoreID set from cache db");
        return;
    }
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_database) == SQLITE_OK) {
        if(deleteScoreStatement == nil) {
            OKLog(@"Preparing statement for delete score");
            const char *deleteSQL = "DELETE FROM OKCACHE WHERE id=?";
            
            if(sqlite3_prepare_v2(_database, deleteSQL, -1, &deleteScoreStatement, NULL) != SQLITE_OK) {
                OKLog(@"Failed to prepare delete score statement with message: %s", sqlite3_errmsg(_database));
                return;
            }
        }
        
        sqlite3_bind_int(deleteScoreStatement, 1, [score OKScoreID]);
        
        if(sqlite3_step(deleteScoreStatement) == SQLITE_DONE) {
            OKLog(@"Removed score with from cache with score id: %d value: %lld & leaderboard id: %d",[score OKScoreID], [score scoreValue], [score OKLeaderboardID]);
        } else {
            OKLog(@"Failed to remove score in cache wihth error message: %s",sqlite3_errmsg(_database));
        }
        
        sqlite3_reset(deleteScoreStatement);
        sqlite3_clear_bindings(deleteScoreStatement);
        sqlite3_close(_database);
        
    } else {
        OKLog(@"Could not open cache db removeScore");
    }
}


-(NSArray*)getAllCachedScores
{
    const char *querySQL = "SELECT * FROM OKCACHE";
    return [self getCachedScoresWithSQL:querySQL];
}

-(NSArray*)getCachedScoresWithSQL:(const char*)querySQL
{
    NSMutableArray *scoresArray = [[NSMutableArray alloc] init];
    
    const char *dbpath = [[self dbPath] UTF8String];
    static sqlite3_stmt *getScoresStatement = nil;
    
    if(sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        if(sqlite3_prepare_v2(_database, querySQL, -1, &getScoresStatement, NULL) == SQLITE_OK){
            while(sqlite3_step(getScoresStatement) == SQLITE_ROW) {
                OKScore *score = [self getScoreFromCacheRow:getScoresStatement];
                [scoresArray addObject:score];
            }
        } else {
            OKLog(@"Could not prepare statement getCacheScoresWithSQL, error: %s", sqlite3_errmsg(_database));
        }
        
    } else {
        OKLog(@"could not open cache db");
    }
    
    return scoresArray;
}


// DB Schema is:
// --------------------------------------------------------------------------------
// | integer | integer       | Bigint     | integer  | varchar(255)  | integer   |
// --------------------------------------------------------------------------------
// | id      | leaderboardID | scoreValue | metadata | displayString | submitted |

-(OKScore*)getScoreFromCacheRow:(sqlite3_stmt*)statement
{
    OKScore *score = [[OKScore alloc] init];
    [score setOKScoreID:sqlite3_column_int(statement, 0)];
    [score setOKLeaderboardID:sqlite3_column_int(statement, 1)];
    [score setScoreValue:sqlite3_column_int64(statement, 2)];
    [score setMetadata:sqlite3_column_int(statement, 3)];
    
    const char* cDisplayString = (const char*)sqlite3_column_text(statement, 4);
    NSString *displayString;
    if(cDisplayString != NULL) {
        displayString = [[NSString alloc] initWithUTF8String:cDisplayString];
    } else {
        displayString = nil;
    }
    if([OKHelper isEmpty:displayString]) {
        [score setDisplayString:nil];
    } else {
        [score setDisplayString:displayString];
    }
    
    //TODO get submitted
    //    int isSubmitted = sqlite3_column_int(statement, 5);

    return score;
}


-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID
{
    OKLog(@"Getting cached scores for leaderboard ID: %d",leaderboardID);
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM OKCACHE WHERE leaderboardID=%d",leaderboardID];
    
    const char* sqlQuery = [queryString UTF8String];
    return [self getCachedScoresWithSQL:sqlQuery];
}


-(void)submitCachedScore:(OKScore*)score
{
    if( [OKUser currentUser]) {
        [score setUser:[OKUser currentUser]];
        
        [score submitScoreWithCompletionHandler:^(NSError *error) {
            if(!error)
            {
                [self removeScore:score];
                OKLog(@"Submitted cached core succesfully");
            }
        }];
        
    } else {
        OKLog(@"Tried to submit a cached score without having an OKUser logged in");
        return;
    }
}


-(void)clearCache
{
    OKLog(@"Clear cached scores");
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_database) == SQLITE_OK) {
        char *errorMsg;
        const char *clearDBStatement = "DROP TABLE IF EXISTS OKCACHE";
        
        if(sqlite3_exec(_database, clearDBStatement, NULL, NULL, &errorMsg) != SQLITE_OK) {
            OKLog(@"Failed to drop cache table");
        } else {
            OKLog(@"Dropped ache table");
        }
        
        sqlite3_close(_database);
    } else {
        OKLog(@"Coud not open DB to drop cache table");
    }

}

-(void)submitAllCachedScores
{
    NSArray *cachedScores = [self getAllCachedScores];
    
    if([cachedScores count] > 0)
    {
        OKLog(@"Submit all cached scores");
        
        for(int x = 0; x < [cachedScores count]; x++)
        {
            OKScore *score = [cachedScores objectAtIndex:x];
            [self submitCachedScore:score];
        }
    }
}

- (void)dealloc
{
    // Do not call super here.  Using arc.
}

@end
