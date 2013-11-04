//
//  OKFMDatabasePool.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class OKFMDatabase;

/** Pool of `<OKFMDatabase>` objects.

 ### See also
 
 - `<OKFMDatabaseQueue>`
 - `<OKFMDatabase>`

 @warning Before using `OKFMDatabasePool`, please consider using `<OKFMDatabaseQueue>` instead.

 If you really really really know what you're doing and `OKFMDatabasePool` is what
 you really really need (ie, you're using a read only database), OK you can use
 it.  But just be careful not to deadlock!

 For an example on deadlocking, search for:
 `ONLY_USE_THE_POOL_IF_YOU_ARE_DOING_READS_OTHERWISE_YOULL_DEADLOCK_USE_FMDATABASEQUEUE_INSTEAD`
 in the main.m file.
 */

@interface OKFMDatabasePool : NSObject {
    NSString            *_path;
    
    dispatch_queue_t    _lockQueue;
    
    NSMutableArray      *_databaseInPool;
    NSMutableArray      *_databaseOutPool;
    
    __unsafe_unretained id _delegate;
    
    NSUInteger          _maximumNumberOfDatabasesToCreate;
}

@property (atomic, retain) NSString *path;
@property (atomic, assign) id delegate;
@property (atomic, assign) NSUInteger maximumNumberOfDatabasesToCreate;

///---------------------
/// @name Initialization
///---------------------

/** Create pool using path.

 @param aPath The file path of the database.

 @return The `OKFMDatabasePool` object. `nil` on error.
 */

+ (instancetype)databasePoolWithPath:(NSString*)aPath;

/** Create pool using path.

 @param aPath The file path of the database.

 @return The `OKFMDatabasePool` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath;

///------------------------------------------------
/// @name Keeping track of checked in/out databases
///------------------------------------------------

/** Number of checked-in databases in pool
 
 @returns Number of databases
 */

- (NSUInteger)countOfCheckedInDatabases;

/** Number of checked-out databases in pool

 @returns Number of databases
 */

- (NSUInteger)countOfCheckedOutDatabases;

/** Total number of databases in pool

 @returns Number of databases
 */

- (NSUInteger)countOfOpenDatabases;

/** Release all databases in pool */

- (void)releaseAllDatabases;

///------------------------------------------
/// @name Perform database operations in pool
///------------------------------------------

/** Synchronously perform database operations in pool.

 @param block The code to be run on the `OKFMDatabasePool` pool.
 */

- (void)inDatabase:(void (^)(OKFMDatabase *db))block;

/** Synchronously perform database operations in pool using transaction.

 @param block The code to be run on the `OKFMDatabasePool` pool.
 */

- (void)inTransaction:(void (^)(OKFMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations in pool using deferred transaction.

 @param block The code to be run on the `OKFMDatabasePool` pool.
 */

- (void)inDeferredTransaction:(void (^)(OKFMDatabase *db, BOOL *rollback))block;

#if SQLITE_VERSION_NUMBER >= 3007000

/** Synchronously perform database operations in pool using save point.

 @param block The code to be run on the `OKFMDatabasePool` pool.

 @warning You can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock. If you need to nest, use `<[OKFMDatabase startSavePointWithName:error:]>` instead.
*/

- (NSError*)inSavePoint:(void (^)(OKFMDatabase *db, BOOL *rollback))block;
#endif

@end


@interface NSObject (OKFMDatabasePoolDelegate)

- (BOOL)databasePool:(OKFMDatabasePool*)pool shouldAddDatabaseToPool:(OKFMDatabase*)database;

@end

