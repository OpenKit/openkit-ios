//
//  OKDBConnection.h
//  OpenKit
//
//  Created by Louis Zell on 8/20/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//
// --------------------------------------------------------------------
//
// This is a very light wrapper over FMDB.  It creates sqlite databases in the
// ApplicationSupport directory. Note, this class is configured to _not_ backup
// contents in iCloud.  If a user changes device, contents of this cache will
// not be found.
//
// Please see the section marked "API".

#define OK_CACHE_USES_MAIN    0
#if OK_CACHE_USES_MAIN
#define OK_CACHE_QUEUE()  dispatch_get_main_queue()
#else
extern dispatch_queue_t __OKCacheQueue;
#define OK_CACHE_QUEUE() ((__OKCacheQueue == nil) ? (__OKCacheQueue = dispatch_queue_create("com.openkit.cache_queue", NULL)) : __OKCacheQueue)
#endif


#import <Foundation/Foundation.h>



@class OKDBConnection;
@class FMDatabase;
@class FMResultSet;


typedef enum
{
    kOKNotSubmitted = 0,
    kOKSubmitted = 1,
    kOKSubmitting = 2,
}OKSubmitState;


static const int OKNoIndex = -1;


@interface OKDBRow : NSObject

@property(nonatomic, readwrite) int rowIndex;
@property(nonatomic, copy) NSDate *modifyDate;
@property(nonatomic, strong) OKDBConnection *dbConnection;
@property(nonatomic, readwrite) OKSubmitState submitState;

- (BOOL)syncWithDB;
- (BOOL)deleteFromDB;
- (NSString*)dbModifyDate;

@end



@interface OKDBConnection : NSObject
{
    NSString *_dbPath;
    NSString *_createSql;
    FMDatabase *_database;
}
@property(nonatomic, readonly) NSString *version;
@property(nonatomic, readonly) NSString *name;

+ (id)sharedConnection;
- (id)initWithName:(NSString *)name createSql:(NSString *)sql version:(NSString *)version;

//! Low level method to establish a connection with the DB.
- (void)access:(void(^)(FMDatabase *))block;

//! You can use this for insert/update/delete without access block.  Selects should
//! go through access block so FMResultSet access is contained.
- (BOOL)update:(NSString *)sql, ...;
- (int)insert:(NSString*)sql, ...;

//! You can use this to select data from the DB connection.
- (void)executeQuery:(NSString*)query access:(void(^)(FMResultSet *))block;
- (BOOL)syncRow:(OKDBRow*)row;
- (BOOL)deleteRow:(OKDBRow *)row;

@end

