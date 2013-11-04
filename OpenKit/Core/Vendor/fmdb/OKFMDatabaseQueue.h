//
//  OKFMDatabaseQueue.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class OKFMDatabase;

/** To perform queries and updates on multiple threads, you'll want to use `OKFMDatabaseQueue`.

 Using a single instance of `<OKFMDatabase>` from multiple threads at once is a bad idea.  It has always been OK to make a `<OKFMDatabase>` object *per thread*.  Just don't share a single instance across threads, and definitely not across multiple threads at the same time.

 Instead, use `OKFMDatabaseQueue`. Here's how to use it:

 First, make your queue.

    OKFMDatabaseQueue *queue = [OKFMDatabaseQueue databaseQueueWithPath:aPath];

 Then use it like so:

    [queue inDatabase:^(OKFMDatabase *db) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        OKFMResultSet *rs = [db executeQuery:@"select * from foo"];
        while ([rs next]) {
            //…
        }
    }];

 An easy way to wrap things up in a transaction can be done like this:

    [queue inTransaction:^(OKFMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        if (whoopsSomethingWrongHappened) {
            *rollback = YES;
            return;
        }
        // etc…
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:4]];
    }];

 `OKFMDatabaseQueue` will run the blocks on a serialized queue (hence the name of the class).  So if you call `OKFMDatabaseQueue`'s methods from multiple threads at the same time, they will be executed in the order they are received.  This way queries and updates won't step on each other's toes, and every one is happy.

 ### See also

 - `<OKFMDatabase>`

 @warning Do not instantiate a single `<OKFMDatabase>` object and use it across multiple threads. Use `OKFMDatabaseQueue` instead.
 
 @warning The calls to `OKFMDatabaseQueue`'s methods are blocking.  So even though you are passing along blocks, they will **not** be run on another thread.

 */

@interface OKFMDatabaseQueue : NSObject {
    NSString            *_path;
    dispatch_queue_t    _queue;
    OKFMDatabase          *_db;
}

@property (atomic, retain) NSString *path;

///----------------------------------------------------
/// @name Initialization, opening, and closing of queue
///----------------------------------------------------

/** Create queue using path.
 
 @param aPath The file path of the database.
 
 @return The `OKFMDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithPath:(NSString*)aPath;

/** Create queue using path.

 @param aPath The file path of the database.

 @return The `OKFMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath;

/** Close database used by queue. */

- (void)close;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations on queue.
 
 @param block The code to be run on the queue of `OKFMDatabaseQueue`
 */

- (void)inDatabase:(void (^)(OKFMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.

 @param block The code to be run on the queue of `OKFMDatabaseQueue`
 */

- (void)inTransaction:(void (^)(OKFMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations on queue, using deferred transactions.

 @param block The code to be run on the queue of `OKFMDatabaseQueue`
 */

- (void)inDeferredTransaction:(void (^)(OKFMDatabase *db, BOOL *rollback))block;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations using save point.

 @param block The code to be run on the queue of `OKFMDatabaseQueue`
 */

#if SQLITE_VERSION_NUMBER >= 3007000
// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use OKFMDatabase's startSavePointWithName:error: instead.
- (NSError*)inSavePoint:(void (^)(OKFMDatabase *db, BOOL *rollback))block;
#endif

@end

