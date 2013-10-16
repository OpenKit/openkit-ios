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

#define START_TIME @"st"
#define E_TIME @"st"
#define START_TIME @"st"
#define START_TIME @"st"


NSMutableArray *__sessions = nil;
NSMutableDictionary *__currentSession = nil;

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
    
    if(__sessions == nil)
        __sessions = [OKAnalytics loadFromCache];
    
    if(__sessions == nil)
        __sessions = [NSMutableArray array];
    
    // TIME TO SEND NOW
    __currentSession = nil;
    [OKAnalytics sendReport];
    
    
    // NEW SESSION
    __currentSession = [NSMutableDictionary dictionaryWithCapacity:10];
    [__currentSession setObject:[OKUtils createUUID] forKey:@"id"]; // session token
    [__currentSession setObject:[OKAnalytics timestamp] forKey:@"st"]; // start time
    [__currentSession setObject:[NSMutableArray array] forKey:@"ev"];
    [__sessions addObject:__currentSession];
}


+ (void)endSession
{
    if(__currentSession) {
        OKLogInfo(@"Ending session");
        [__currentSession setObject:[OKAnalytics timestamp] forKey:@"et"]; // end time
        __currentSession = nil;
        
        // TIME TO WRITE TO THE FILE
        [__sessions writeToFile:[OKAnalytics persistentPath] atomically:YES];        
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
                              typeName, @"t",
                              [OKAnalytics timestamp], @"ts",
                              metadata, @"m", nil];
    
    
    // add new event
    NSMutableArray *eventsArray = [__currentSession objectForKey:@"ev"];
    [eventsArray addObject:newEvent];
}


+ (void)sendReport
{
    if([__sessions count]>0) {
        OKLogInfo(@"Sending report");
        if(__currentSession) {
            OKLogErr(@"ONE SESSION IS OPEN YET, we can not send the report.");
            return;
        }
        // first we copy the array of session we want to send
        NSArray *toSend = [NSArray arrayWithArray:__sessions];
        NSDictionary *params = [NSDictionary dictionaryWithObject:toSend forKey:@"sessions"];
        
        NSURL *url = [NSURL URLWithString:@"http://toddham.com/chat"];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        [httpClient setParameterEncoding:AFJSONParameterEncoding];
        [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
        [httpClient postPath:@"analytics_post.php"
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             OKLogInfo(@"SUCCESS, removing cache");
             NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             NSLog(@"Request Successful, response '%@'", responseStr);
             [OKAnalytics removeCache];
             [__sessions removeObjectsInArray:toSend];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             OKLogErr(@"[HTTPClient Error], we do not remove the cache");
         }];
    }
}



@end
