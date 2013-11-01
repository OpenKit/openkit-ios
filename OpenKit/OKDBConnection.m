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
    NSParameterAssert(name);
    NSParameterAssert(sql);
    NSParameterAssert(version);
    
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
    NSParameterAssert(block);

    [self sanity];
    FMDatabase *db = [self database];
    if ([db open]){
        block(db);
        [db close];
    } else {
        OKLogErr(@"OKDBConnection: Could not open db in local cache.");
    }
}


- (int64_t)insert:(NSString*)sql,...
{
    va_list *args = (va_list*)malloc(sizeof(va_list));
    va_start(*args, sql);
    
    __block int64_t index = -1;
    [self access:^(FMDatabase *db) {

        if([db executeQuery:sql withVAList:*args]) {
            index = [db lastInsertRowId];
        }else{
            OKLogErr(@"OKDBConnection: FAIL performing: %@", sql);
        }
    }];
    va_end(*args);
    free(args);
    
    return index;
}


- (BOOL)update:(NSString *)sql, ...
{
    va_list *args = (va_list*)malloc(sizeof(va_list));
    va_start(*args, sql);

    __block BOOL success = NO;
    [self access:^(FMDatabase *db) {
        success = [db executeUpdate:sql withVAList:*args];
        if(!success)
            OKLogErr(@"OKDBConnection: FAIL performing: %@", sql);
    }];
    va_end(*args);
    free(args);

    return success;
}


- (void)executeQuery:(NSString*)sql access:(void(^)(FMResultSet *))block
{
    [self access:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        if(!rs)
            OKLogErr(@"OKDBConnection: FAIL performing: %@", sql);
        
        block(rs);
    }];
}


- (BOOL)syncRow:(OKDBRow*)row
{
    if(!row)
        return NO;
    
    NSDate *now = [NSDate date];
    [row setDbConnection:self];
    [row setModifyDate:now];
    
    BOOL success = NO;
    
    if(row.rowIndex == OKNoIndex) {
        // Is the row index is invalid, we insert a new row
        [row setCreateDate:now];
        NSInteger index = [self insertRow:row];
        if(index != -1) {
            success = YES;
            [row setRowIndex:index];
        }
        
    }else{
        // Is the row index is valid, we update it
        success = [self updateRow:row];
    }
    
    return success;
}


- (NSInteger)insertRow:(OKDBRow*)row
{
    NSAssert(NO, @"This method should be override");
    return NO;
}


- (BOOL)updateRow:(OKDBRow*)row
{
    NSAssert(NO, @"This method should be override");
    return NO;
}


- (BOOL)deleteRow:(OKDBRow*)row
{
    NSAssert(NO, @"This method should be override");
    return NO;
}


#pragma mark - Private

-(FMDatabase *)database
{
    if (_database == nil) {
        _database = [FMDatabase databaseWithPath:[self dbPath]];
     
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_database setDateFormat:dateFormatter];
    }
    
    return _database;
}


- (BOOL)executeCreateSql
{
    if (![[self database] open]) {
        OKLogErr(@"OKDBConnection: Could not open database in OKLocalCache.");
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


- (NSString*)cacheDirPath
{
    return [OKFileUtil localOnlyCachePath];
}


- (NSString*)dbPath
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
        OKLogInfo(@"OKDBConnection: Executing create sql for db at %@", [self dbPath]);
        if (![self executeCreateSql]) {
            OKLogErr(@"OKDBConnection: Could not execute create sql.");
        }
    }
}

@end
