//
//  OKLocalCache.m
//  OpenKit
//
//  Created by Louis Zell on 8/20/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "FMDatabase.h"
#import "OKDBConnection.h"
#import "OKMacros.h"
#import "OKFileUtil.h"
#import "OKUtils.h"

#if !OK_CACHE_USES_MAIN
dispatch_queue_t __OKCacheQueue = nil;
#endif


@implementation OKDBRow

- (id)init
{
    self = [super init];
    if (self) {
        _rowIndex = OKNoIndex;
        _submitState = kOKNotSubmitted;
        _dbConnection = nil;
        _modifyDate = nil;
    }
    return self;
}


- (BOOL)syncWithDB
{
    return [_dbConnection syncRow:self];
}


- (BOOL)deleteFromDB
{
    return [_dbConnection deleteRow:self];
}

- (NSString*)dbModifyDate
{
    return [OKUtils sqlStringFromDate:self.modifyDate];
}

@end



@implementation OKDBConnection

#pragma mark - API

+ (id)sharedConnection
{
    NSAssert(NO, @"This method should be override");
    return nil;
}


- (id)initWithName:(NSString *)name createSql:(NSString *)sql version:(NSString *)version
{
    if ((self = [super init])) {
        _dbPath = nil;
        _name = [name copy];
        _createSql = [sql copy];
        _version = [version copy];
    }
    return self;
}


-(void)access:(void(^)(FMDatabase *))block
{
    [self sanity];
    FMDatabase *db = [self database];
    if ([db open]){
        block(db);
        [db close];
    } else {
        OKLogErr(@"Could not open db in local cache.");
    }
}


- (BOOL)update:(NSString *)sql, ...
{
    va_list args;
    va_start(args, sql);

    __block BOOL success;
    [self access:^(FMDatabase *db) {
        OKLogInfo(@"DBConnection: Performing cache update: %@", sql);
        success = [db executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
        OKLogInfo(@"    ...%@", (success ? @"success" : @"FAIL"));
    }];
    va_end(args);

    return success;
}


- (void)executeQuery:(NSString*)sql access:(void(^)(FMResultSet *))block
{
    [self access:^(FMDatabase *db){
        OKLogInfo(@"DBConnection: Performing cache query: %@", sql);

        FMResultSet *rs = [db executeQuery:sql];
        OKLogInfo(@"    ...%@", (rs ? @"success" : @"FAIL"));
        block(rs);
    }];
}


- (BOOL)syncRow:(OKDBRow*)row
{
    [row setDbConnection:self];
    [row setModifyDate:[NSDate date]];
    
    BOOL success = NO;
    BOOL insert = row.rowIndex == OKNoIndex;
    if(insert)
        success = [self insertRow:row];
    else
        success = [self updateRow:row];
    
    
    if(!success) {
        OKLogErr(@"Could not insert the row.");
        return NO;
    }
    
    // Get row id and update OKDBRow
    if(insert) {
        int index = [self lastModifiedIndex];
        if(index == -1) {
            OKLogErr(@"Could not get the index.");
            return NO;
        }
        
        [row setRowIndex:index];
    }
    return YES;
}


- (int)lastModifiedIndex
{
    NSAssert(NO, @"This method should be override");
    return -1;
}


- (BOOL)insertRow:(OKDBRow*)row
{
    NSAssert(NO, @"This method should be override");
    return NO;
}


- (BOOL)updateRow:(OKDBRow *)row
{
    NSAssert(NO, @"This method should be override");
    return NO;
}


- (BOOL)deleteRow:(OKDBRow *)row
{
    NSAssert(NO, @"This method should be override");
    return NO;
}


#pragma mark - Private

-(FMDatabase *)database
{
    if (_database == nil)
        _database = [FMDatabase databaseWithPath:[self dbPath]];
    
    return _database;
}


- (BOOL)executeCreateSql
{
    if (![[self database] open]) {
        OKLogErr(@"Could not open database in OKLocalCache.");
        return NO;
    }

    BOOL failed = NO;
    for (NSString *create in [_createSql componentsSeparatedByString:@"\n"]) {
        if (![[self database] executeUpdate:create]) {
            failed = YES;
            break;
        }
    }
    [[self database] close];
    return !failed;
}


- (NSString *)cacheDirPath
{
    return [OKFileUtil localOnlyCachePath];
}


- (NSString *)dbPath
{
    if(_dbPath == nil) {
        NSString *s = [NSString stringWithFormat:@"%@-%@.sqlite", _name, _version];
        _dbPath = [[self cacheDirPath] stringByAppendingPathComponent:s];
    }
    return _dbPath;
}


- (BOOL)dbExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[self dbPath]];
}


-(void)sanity
{
    if (![self dbExists]) {
        OKLogInfo(@"Executing create sql for db at %@", [self dbPath]);
        if (![self executeCreateSql]) {
            OKLogErr(@"Could not execute create sql.");
        }
    }
}

@end
