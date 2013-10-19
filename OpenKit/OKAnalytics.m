#import "OKAnalytics.h"
#import "OKUtils.h"
#import "OKHelper.h"
#import "OKFileUtil.h"
#import "OKMacros.h"
#import "OKManager.h"
#import "OKNetworker.h"


NSMutableArray *__events = nil;
NSString *__currentSession = nil;

@implementation OKAnalytics

+ (NSString*)persistentPath
{
    NSString *path = [OKFileUtil localOnlyCachePath];
    path = [path stringByAppendingPathComponent:@"ok_analytics.plist"];
    return path;
}


+ (NSMutableArray*)loadFromCache
{
    return [NSMutableArray arrayWithContentsOfFile:[OKAnalytics persistentPath]];
}


+ (void)removeCache
{
    [[NSFileManager defaultManager] removeItemAtPath:[OKAnalytics persistentPath] error:nil];
}


+ (NSNumber*)timestamp
{
    return [NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]];
}


+ (void)startSession
{
    OKLogInfo(@"Starting session...");
    if(__currentSession) {
        OKLogErr(@"Error, a session is still open. Closing...");
        [OKAnalytics endSession];
    }
    
    if(__events == nil)
        __events = [OKAnalytics loadFromCache];
    
    if(__events == nil)
        __events = [NSMutableArray array];
    
    // TIME TO SEND NOW
    __currentSession = nil;
    [OKAnalytics sendReportWithCompletion:nil];
    
    
    // NEW SESSION
    __currentSession = [OKUtils createUUID];
    [OKAnalytics postEvent:@"start_session" metadata:nil];
}


+ (void)endSession
{
    if(__currentSession) {
        OKLogInfo(@"Ending session");
        [OKAnalytics postEvent:@"end_session" metadata:nil];
        __currentSession = nil;
    }
}


+ (void)postEvent:(NSString*)typeName metadata:(id)metadata
{
    OKLogInfo(@"Posting event: %@", typeName);

    if(!__currentSession) {
        OKLogErr(@"An analytics session hasn't been started.  Start one before posting events.");
        return;
    }

    // create new event
    NSDictionary *newEvent = [NSDictionary dictionaryWithObjectsAndKeys:
                              [OKUtils createUUID]    , @"id",
                              __currentSession        , @"session",
                              typeName                , @"type",
                              [OKAnalytics timestamp] , @"timestamp",
                              metadata                , @"meta",
                              nil];
    
    [__events addObject:newEvent];
    [__events writeToFile:[OKAnalytics persistentPath] atomically:YES];
}


+ (void)sendReportWithCompletion:(void(^)(NSError*error))handler;
{
    if([__events count]>0) {
        OKLogInfo(@"Sending report");
        // first we copy the array of session we want to send
        NSArray *toSend = [NSArray arrayWithArray:__events];
        NSData *data = [NSJSONSerialization dataWithJSONObject:toSend options:0 error:nil];
        NSString *events = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                events, @"events",
                                nil];

        [OKNetworker postEvents:params handler:^(NSError *error) {
            if (error) {
                OKLogErr(@"Failed to post events, we do not remove the cache");
                if(handler)
                    handler(error);
            } else {
                OKLogInfo(@"SUCCESS, removing cache");
                [OKAnalytics removeCache];
                [__events removeObjectsInArray:toSend];
                if(handler)
                    handler(nil);
            }
        }];
    }
}



@end
