//
//  OKManager.m
//  OKManager
//
//  Created by Suneet Shah on 12/27/12.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKAnalytics.h"
#import "OKUtils.h"
#import "OKHelper.h"
#import "OKFileUtil.h"
#import "AFNetworking.h"
#import "OKMacros.h"
#import "OKManager.h"

#define START_TIME @"st"
#define E_TIME @"st"
#define START_TIME @"st"
#define START_TIME @"st"


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
        OKLogErr(@"NO SESSION IS OPEN YET, start it before posting events.");
        return;
    }

    // create new event
    NSDictionary *newEvent = [NSDictionary dictionaryWithObjectsAndKeys:
                              [OKUtils createUUID], @"id",
                              __currentSession, @"session",
                              typeName, @"t",
                              [OKAnalytics timestamp], @"ts",
                              metadata, @"m", nil];
    
    [__events addObject:newEvent];
    [__events writeToFile:[OKAnalytics persistentPath] atomically:YES];
}


+ (void)sendReportWithCompletion:(void(^)(NSError*error))handler;
{
    if([__events count]>0) {
        OKLogInfo(@"Sending report");
        // first we copy the array of session we want to send
        NSArray *toSend = [NSArray arrayWithArray:__events];
        NSDictionary *params = [NSDictionary dictionaryWithObject:toSend forKey:@"events"];
        
        
        NSString *path = [NSString stringWithFormat:@"analytics_post.php?key=%@", [OKManager appKey]];
        NSLog(@"%@", path);
        NSURL *url = [NSURL URLWithString:@"http://toddham.com/chat"];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        [httpClient setParameterEncoding:AFJSONParameterEncoding];
        [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
        [httpClient postPath:path
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             OKLogInfo(@"SUCCESS, removing cache");
             NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             NSLog(@"Request Successful, response '%@'", responseStr);
             [OKAnalytics removeCache];
             [__events removeObjectsInArray:toSend];
             
             if(handler)
                 handler(nil);
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             OKLogErr(@"[HTTPClient Error], we do not remove the cache");
             if(handler)
                 handler(nil);
         }];
    }
}



@end
