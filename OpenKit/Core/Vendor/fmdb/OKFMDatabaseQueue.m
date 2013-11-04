//
//  OKFMDatabaseQueue.m
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import "OKFMDatabaseQueue.h"
#import "OKFMDatabase.h"

/*
 
 Note: we call [self retain]; before using dispatch_sync, just incase 
 OKFMDatabaseQueue is released on another thread and we're in the middle of doing
 something in dispatch_sync
 
 */
 
@implementation OKFMDatabaseQueue

@synthesize path = _path;

+ (instancetype)databaseQueueWithPath:(NSString*)aPath {
    
    OKFMDatabaseQueue *q = [[self alloc] initWithPath:aPath];
    
    OKFMDBAutorelease(q);
    
    return q;
}

- (instancetype)initWithPath:(NSString*)aPath {
    
    self = [super init];
    
    if (self != nil) {
        
        _db = [OKFMDatabase databaseWithPath:aPath];
        OKFMDBRetain(_db);
        
        if (![_db open]) {
            NSLog(@"Could not create database queue for path %@", aPath);
            OKFMDBRelease(self);
            return 0x00;
        }
        
        _path = OKFMDBReturnRetained(aPath);
        
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"fmdb.%@", self] UTF8String], NULL);
    }
    
    return self;
}

- (void)dealloc {
    
    OKFMDBRelease(_db);
    OKFMDBRelease(_path);
    
    if (_queue) {
        OKFMDBDispatchQueueRelease(_queue);
        _queue = 0x00;
    }
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    OKFMDBRetain(self);
    dispatch_sync(_queue, ^() { 
        [_db close];
        OKFMDBRelease(_db);
        _db = 0x00;
    });
    OKFMDBRelease(self);
}

- (OKFMDatabase*)database {
    if (!_db) {
        _db = OKFMDBReturnRetained([OKFMDatabase databaseWithPath:_path]);
        
        if (![_db open]) {
            NSLog(@"OKFMDatabaseQueue could not reopen database for path %@", _path);
            OKFMDBRelease(_db);
            _db  = 0x00;
            return 0x00;
        }
    }
    
    return _db;
}

- (void)inDatabase:(void (^)(OKFMDatabase *db))block {
    OKFMDBRetain(self);
    
    dispatch_sync(_queue, ^() {
        
        OKFMDatabase *db = [self database];
        block(db);
        
        if ([db hasOpenResultSets]) {
            NSLog(@"Warning: there is at least one open result set around after performing [OKFMDatabaseQueue inDatabase:]");
        }
    });
    
    OKFMDBRelease(self);
}


- (void)beginTransaction:(BOOL)useDeferred withBlock:(void (^)(OKFMDatabase *db, BOOL *rollback))block {
    OKFMDBRetain(self);
    dispatch_sync(_queue, ^() { 
        
        BOOL shouldRollback = NO;
        
        if (useDeferred) {
            [[self database] beginDeferredTransaction];
        }
        else {
            [[self database] beginTransaction];
        }
        
        block([self database], &shouldRollback);
        
        if (shouldRollback) {
            [[self database] rollback];
        }
        else {
            [[self database] commit];
        }
    });
    
    OKFMDBRelease(self);
}

- (void)inDeferredTransaction:(void (^)(OKFMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:YES withBlock:block];
}

- (void)inTransaction:(void (^)(OKFMDatabase *db, BOOL *rollback))block {
    [self beginTransaction:NO withBlock:block];
}

#if SQLITE_VERSION_NUMBER >= 3007000
- (NSError*)inSavePoint:(void (^)(OKFMDatabase *db, BOOL *rollback))block {
    
    static unsigned long savePointIdx = 0;
    __block NSError *err = 0x00;
    OKFMDBRetain(self);
    dispatch_sync(_queue, ^() { 
        
        NSString *name = [NSString stringWithFormat:@"savePoint%ld", savePointIdx++];
        
        BOOL shouldRollback = NO;
        
        if ([[self database] startSavePointWithName:name error:&err]) {
            
            block([self database], &shouldRollback);
            
            if (shouldRollback) {
                [[self database] rollbackToSavePointWithName:name error:&err];
            }
            else {
                [[self database] releaseSavePointWithName:name error:&err];
            }
            
        }
    });
    OKFMDBRelease(self);
    return err;
}
#endif

@end
