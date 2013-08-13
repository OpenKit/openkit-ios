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
        
        const char *dbpath = [[self dbPath] UTF8String];
        
        if(sqlite3_open(dbpath, &_database) == SQLITE_OK) {
            char *errorMsg;
            const char *dbInitStatement = "CREATE TABLE IF NOT EXISTS OKCACHE(id INTEGER PRIMARY KEY AUTOINCREMENT, leaderboardID INTEGER, scoreValue BIGINT, metadata INTEGER, displayString VARCHAR(255), submitted BOOLEAN);";
            
            if(sqlite3_exec(_database, dbInitStatement, NULL, NULL, &errorMsg) != SQLITE_OK) {
                OKLog(@"Failed to create cache table");
            } else {
                OKLog(@"Created/found cache table");
            }
            
            //TODO close?
            sqlite3_close(_database);
        } else {
            OKLog(@"Failed to open/create database");
        }
    } else {
        OKLog(@"Cache DB file found");
    }
}

-(void)storeArrayOfEncodedScoresInDefaults:(NSArray*)encodedScores
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:encodedScores forKey:SCORES_CACHE_KEY];
    [defaults synchronize];
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


-(void)storeScore:(OKScore*)score
{
    NSMutableArray *mutableScoreCache = [[NSMutableArray alloc] initWithArray:[self getCachedEncodedScoresArray]];
    NSData *encodedScore = [NSKeyedArchiver archivedDataWithRootObject:score];
    [mutableScoreCache addObject:encodedScore];
    
    [self storeArrayOfEncodedScoresInDefaults:mutableScoreCache];
    
    OKLog(@"Cached score with value: %lld & leaderboard id: %d",[score scoreValue], [score OKLeaderboardID]);
    
}

-(NSArray*)getCachedScores
{
    NSMutableArray *scoreArray = [[NSMutableArray alloc] init];
    NSArray *encodedScoresArray = [self getCachedEncodedScoresArray];
    
    for(int x = 0; x < [encodedScoresArray count]; x++)
    {
        NSData *encodedScore = [encodedScoresArray objectAtIndex:x];
        OKScore *score = (OKScore *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedScore];
        [scoreArray addObject:score];
    }
    
    //OKLog(@"Got %d cached scores", [encodedScoresArray count]);
    return scoreArray;
}

-(NSArray*)getAllCachedScores
{
    NSMutableArray *scoresArray = [[NSMutableArray alloc] init];
    
    const char *dbpath = [[self dbPath] UTF8String];
    static sqlite3_stmt *getAllScoresStatement = nil;
    
    if(sqlite3_open(dbpath, &_database) == SQLITE_OK)
    {
        const char *querySQL = "SELECT * FROM OKCACHE";
        
        if(sqlite3_prepare_v2(_database, querySQL, -1, &getAllScoresStatement, NULL) == SQLITE_OK){
            while(sqlite3_step(getAllScoresStatement) == SQLITE_ROW) {
                OKScore *score = [self getScoreFromCacheRow:getAllScoresStatement];
                [scoresArray addObject:score];
            }
        } else {
            OKLog(@"Could not prepare statement");
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



-(void)removeScoreFromCache:(OKScore*)scoreToRemove
{
    NSArray *cachedEncodedScores = [self getCachedEncodedScoresArray];
    NSMutableArray *mutableScoreCache = [[NSMutableArray alloc] init];
    
    // Copy the array (cache) but exclude the item to be removed
    for(int x = 0; x < [cachedEncodedScores count]; x++)
    {
        NSData *encodedScore = [cachedEncodedScores objectAtIndex:x];
        OKScore *score = (OKScore *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedScore];
        
        if([score OKScoreID] == [scoreToRemove OKScoreID]) {
            // Don't add it to the new one
            OKLog(@"Removed cached score ID: %d", [scoreToRemove OKScoreID]);
        } else {
            [mutableScoreCache addObject:encodedScore];
        }
    }
    
    [self storeArrayOfEncodedScoresInDefaults:mutableScoreCache];
}


-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID
{
    NSArray *cachedScores = [self getCachedScores];
    
    NSMutableArray *leaderboardScores = [[NSMutableArray alloc] init];
    
    for(int x = 0; x < [cachedScores count]; x++)
    {
        OKScore *score = [cachedScores objectAtIndex:x];
        
        if([score OKLeaderboardID] == leaderboardID)
            [leaderboardScores addObject:score];
    }
    
    return leaderboardScores;
}

-(NSArray*)getCachedEncodedScoresArray
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *scoresCache = [defaults objectForKey:SCORES_CACHE_KEY];
    
    // If the cache is not found, return an empty array
    if(scoresCache == nil || ![scoresCache isKindOfClass:[NSArray class]]) {
        return [[NSArray alloc] init];
    } else {
        return scoresCache;
    }
}

-(void)submitCachedScore:(OKScore*)score
{
    if( [OKUser currentUser]) {
        [score setUser:[OKUser currentUser]];
        
        [score submitScoreWithCompletionHandler:^(NSError *error) {
            if(!error)
            {
                [self removeScoreFromCache:score];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:SCORES_CACHE_KEY];
    [defaults synchronize];
}

-(void)submitAllCachedScores
{
    NSArray *cachedScores = [self getCachedScores];
    
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
