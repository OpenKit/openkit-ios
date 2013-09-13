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
#import "OKFileUtil.h"
#import "OKNetworker.h"

#define SCORES_CACHE_KEY @"OKLeaderboardScoresCache"

static NSString *dbVersion = @"1";

@implementation OKScoreCache
{
    sqlite3* _scoresDB;
}

@synthesize lastScore;


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


- (NSString *)cacheDirPath
{
    return [OKFileUtil localOnlyCachePath];
}

- (NSString *)dbPath
{
    NSString *relativeDBPath = [NSString stringWithFormat:@"okScoreCache-%@.sqlite", dbVersion];
    return [[self cacheDirPath] stringByAppendingPathComponent:relativeDBPath];
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
        OKLog(@"Creating OKScoreCache DB file");
    } else {
        OKLog(@"OKScoreCache DB file found");
    }
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK) {
        char *errorMsg;
        const char *dbInitStatement = "CREATE TABLE IF NOT EXISTS OKCACHE(id INTEGER PRIMARY KEY AUTOINCREMENT, leaderboardID INTEGER, scoreValue BIGINT, metadata INTEGER, displayString VARCHAR(255), submitted BOOLEAN);";
        
        if(sqlite3_exec(_scoresDB, dbInitStatement, NULL, NULL, &errorMsg) != SQLITE_OK) {
            OKLog(@"Failed to create OKScoreCache table");
        } else {
            OKLog(@"Created or found OKScoreCache table");
        }
        
        sqlite3_close(_scoresDB);
    } else {
        OKLog(@"Failed to open/create _scoresDB");
    }
}


-(void)insertScore:(OKScore*)score
{
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK) {
        
        // Setup the SQL Statement
        sqlite3_stmt *insertScoreStatement = nil;
        static const char *insertSQL = "INSERT INTO OKCACHE(leaderboardID,scoreValue,metadata,displayString,submitted) VALUES(?,?,?,?,?);";
        
        if(sqlite3_prepare_v2(_scoresDB, insertSQL, -1, &insertScoreStatement, NULL) != SQLITE_OK) {
            OKLog(@"Failed to prepare score insert statement with message: '%s'", sqlite3_errmsg(_scoresDB));
            return;
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
        sqlite3_bind_int(insertScoreStatement, 5, (int)[score submitted]);
        
        //Execute the SQL statement
        if(sqlite3_step(insertScoreStatement) == SQLITE_DONE) {
            int scoreID = sqlite3_last_insert_rowid(_scoresDB);
            [score setOKScoreID:scoreID];
            OKLog(@"Cached score : %@",score);
        } else {
            OKLog(@"Failed to store score in cache wihth error message: %s",sqlite3_errmsg(_scoresDB));
        }
        
        sqlite3_finalize(insertScoreStatement);
        sqlite3_close(_scoresDB);
        
    } else {
        OKLog(@"Could not open cache DB insertScore");
    }
}

-(void)deleteScore:(OKScore*)score
{
    if(![score OKScoreID]) {
        OKLog(@"Tried to remove a score without a scoreID set from cache db");
        return;
    }
    
    const char *dbpath = [[self dbPath] UTF8String];
    sqlite3_stmt *deleteScoreStatement = nil;
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK) {
        //Prepare the SQL statement
        static const char *deleteSQL = "DELETE FROM OKCACHE WHERE id=?";
        
        if(sqlite3_prepare_v2(_scoresDB, deleteSQL, -1, &deleteScoreStatement, NULL) != SQLITE_OK) {
            OKLog(@"Failed to prepare delete score statement with message: %s", sqlite3_errmsg(_scoresDB));
            return;
        }
        
        sqlite3_bind_int(deleteScoreStatement, 1, [score OKScoreID]);
        
        if(sqlite3_step(deleteScoreStatement) == SQLITE_DONE) {
            OKLog(@"Removed score %@", score);
        } else {
            OKLog(@"Failed to remove score in cache wihth error message: %s",sqlite3_errmsg(_scoresDB));
        }
        
        sqlite3_finalize(deleteScoreStatement);
        sqlite3_close(_scoresDB);
    } else {
        OKLog(@"Could not open cache db removeScore");
    }
}


-(NSArray*)getAllCachedScores
{
    const char *querySQL = "SELECT * FROM OKCACHE";
    return [self getCachedScoresWithSQL:querySQL];
}

-(NSArray*)getCachedScoresForLeaderboardID:(int)leaderboardID andOnlyGetSubmittedScores:(BOOL)submittedOnly
{
    //OKLog(@"Getting cached scores for leaderboard ID: %d",leaderboardID);
    NSString *queryString;
    
    if(submittedOnly) {
        queryString = [NSString stringWithFormat:@"SELECT * FROM OKCACHE WHERE leaderboardID=%d AND submitted=1",leaderboardID];
    } else {
        queryString = [NSString stringWithFormat:@"SELECT * FROM OKCACHE WHERE leaderboardID=%d",leaderboardID];
    }
    const char* sqlQuery = [queryString UTF8String];
    return [self getCachedScoresWithSQL:sqlQuery];
}

-(NSArray*)getUnsubmittedCachedScores
{
    NSString *queryString = [NSString stringWithFormat:@"SELECT * FROM OKCACHE WHERE submitted=0"];
    const char* sqlQuery = [queryString UTF8String];
    return [self getCachedScoresWithSQL:sqlQuery];
}

-(NSArray*)getCachedScoresWithSQL:(const char*)querySQL
{
    NSMutableArray *scoresArray = [[NSMutableArray alloc] init];
    
    const char *dbpath = [[self dbPath] UTF8String];
    static sqlite3_stmt *getScoresStatement = nil;
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK)
    {
        if(sqlite3_prepare_v2(_scoresDB, querySQL, -1, &getScoresStatement, NULL) == SQLITE_OK){
            while(sqlite3_step(getScoresStatement) == SQLITE_ROW) {
                OKScore *score = [self getScoreFromCacheRow:getScoresStatement];
                [scoresArray addObject:score];
            }
        } else {
            OKLog(@"Could not prepare statement getCacheScoresWithSQL, error: %s", sqlite3_errmsg(_scoresDB));
        }
        
    } else {
        OKLog(@"could not open cache db");
    }
    
    return scoresArray;
}

-(void)updateCachedScoreSubmitted:(OKScore*)score
{
    if(![score OKScoreID]) {
        OKLog(@"Tried to update a score without a scoreID set from cache db");
        return;
    }
    
    sqlite3_stmt *updateScoreStatement = nil;
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK) {
        static const char *updateSQL = "UPDATE OKCACHE SET Submitted=1 WHERE id=?";
        
        if(sqlite3_prepare_v2(_scoresDB, updateSQL, -1, &updateScoreStatement, NULL) != SQLITE_OK) {
            OKLog(@"Failed to prepare update score statement with message: %s", sqlite3_errmsg(_scoresDB));
            return;
        }
        
        
        sqlite3_bind_int(updateScoreStatement, 1, [score OKScoreID]);
        
        if(sqlite3_step(updateScoreStatement) == SQLITE_DONE) {
            //OKLog(@"Update score submitted %@", score);
        } else {
            OKLog(@"Failed to remove score in cache wihth error message: %s",sqlite3_errmsg(_scoresDB));
        }
        
        sqlite3_finalize(updateScoreStatement);
        sqlite3_close(_scoresDB);
        
    } else {
        OKLog(@"Could not open cache db removeScore");
    }
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
    
    int isSubmitted = sqlite3_column_int(statement, 5);
    [score setSubmitted:(BOOL)isSubmitted];
    
    return score;
}


-(void)submitCachedScore:(OKScore*)score
{
    if([OKUser currentUser]) {
        [score setUser:[OKUser currentUser]];
        
        [score cachedScoreSubmit:^(NSError *error) {
            if(!error) {
                [self updateCachedScoreSubmitted:score];
                OKLog(@"Submitted cached core succesfully");
            } else {
                // If the error code returned is in the 400s, delete the score from the cache
                int errorCode = [OKNetworker getStatusCodeFromAFNetworkingError:error];
                if(errorCode >= 400 && errorCode <= 500) {
                    OKLog(@"Deleted cached score because of error code: %d",errorCode);
                    [self deleteScore:score];
                }
                OKLog(@"Failed to submit cached score");
            }
        }];
        
    } else {
        OKLog(@"Tried to submit a cached score without having an OKUser logged in");
        return;
    }
}

/*
-(void)clearCache
{
    OKLog(@"Clear cached scores");
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK) {
        char *errorMsg;
        const char *clearDBStatement = "DROP TABLE IF EXISTS OKCACHE";
        
        if(sqlite3_exec(_scoresDB, clearDBStatement, NULL, NULL, &errorMsg) != SQLITE_OK) {
            OKLog(@"Failed to drop cache table");
        } else {
            OKLog(@"Dropped cache table");
        }
        
        
    } else {
        OKLog(@"Coud not open DB to drop cache table");
    }
    
    [self closeDB];
    
    //Reinit the DB after clearing out the cache
    [self initDB];
}*/

-(void)clearCachedSubmittedScores
{
    OKLog(@"Clear cached submitted scores");
    OKLog(@"Score cache before delete: %@", [self getAllCachedScores]);
    
    const char *dbpath = [[self dbPath] UTF8String];
    
    if(sqlite3_open(dbpath, &_scoresDB) == SQLITE_OK) {
        char *errorMsg;
        const char *clearDBStatement = "DELETE FROM OKCACHE WHERE submitted=1";
        
        if(sqlite3_exec(_scoresDB, clearDBStatement, NULL, NULL, &errorMsg) != SQLITE_OK) {
            OKLog(@"Failed to delete cached submitted scores");
        } else {
            OKLog(@"Cleared all cached submitted scores");
        }
        
    } else {
        OKLog(@"Failed to open database to clear cached scores");
    }
    
    
    OKLog(@"Score cache after delete: %@", [self getAllCachedScores]);
}

-(void)closeDB
{
    sqlite3_close(_scoresDB);
}

-(void)submitAllCachedScores
{
    if(![OKUser currentUser])
        return;
    
    NSArray *cachedScores = [self getUnsubmittedCachedScores];
    
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

-(BOOL)isScoreBetterThanLocalCachedScores:(OKScore *)score
{
    return [self isScoreBetterThanLocalCachedScores:score storeScore:NO];
}

-(void)storeScoreIfBetter:(OKScore*)score
{
    [self isScoreBetterThanLocalCachedScores:score storeScore:YES];
}

//Returns YES if the score is stored in the cache
-(BOOL)isScoreBetterThanLocalCachedScores:(OKScore*)scoreToStore storeScore:(BOOL)shouldStoreScore
{
    // if (score) > largestCachedScore || score < lowestCachedScore )
    // store it
    // return YES
    // else
    // don't store it, return no
    
    // If there is a user logged in, we should compare against scores that have already been submitted to decide whether
    // to submit the new score, and not all scores. E.g. if there is an unsubmitted score for some reason that has a higher value than the
    // one to submit, we should still submit it. This is because for some reason there might be an unsubmitted score stored that will never
    // get submitted for some unknown reason.
    
    
    NSArray *cachedScores;
    if([OKUser currentUser]) {
        cachedScores = [self getCachedScoresForLeaderboardID:[scoreToStore OKLeaderboardID] andOnlyGetSubmittedScores:YES];
    } else {
        cachedScores = [self getCachedScoresForLeaderboardID:[scoreToStore OKLeaderboardID] andOnlyGetSubmittedScores:NO];
    }
    
    int numCachedScores = [cachedScores count];
    
    if(numCachedScores <= 1) {
        if(shouldStoreScore) {
            [self insertScore:scoreToStore];
        }
        [self setLastScore:nil];
        return YES;
    } else {
        NSArray *sortedCachedScores = [OKScoreCache sortScoresDescending:cachedScores];
        
        OKScore *highestScore = [sortedCachedScores objectAtIndex:0];
        OKScore *lowestScore = [sortedCachedScores objectAtIndex:numCachedScores-1];
        
        if([scoreToStore scoreValue] > [highestScore scoreValue]) {
            if(shouldStoreScore) {
                [self insertScore:scoreToStore];
                [self deleteScore:highestScore];
            }
            [self setLastScore:highestScore];
            return YES;
        } else if ([scoreToStore scoreValue] < [lowestScore scoreValue]) {
            if(shouldStoreScore) {
                [self insertScore:scoreToStore];
                [self deleteScore:lowestScore];
            }
            [self setLastScore:lowestScore];
            return YES;
        }
    }
    
    return NO;
}


+(NSArray*)sortScoresDescending:(NSArray*)scores
{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"scoreValue" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [scores sortedArrayUsingDescriptors:sortDescriptors];
    
    return sortedArray;
}

- (void)dealloc
{
    // Do not call super here.  Using arc.
}

@end
