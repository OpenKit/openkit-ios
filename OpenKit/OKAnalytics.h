#import <Foundation/Foundation.h>

@interface OKAnalytics : NSObject

+ (void)startSession;
+ (void)endSession;
+ (void)sendReportWithCompletion:(void(^)(NSError*error))handler;
+ (void)postEvent:(NSString*)typeName metadata:(id)metadata;

@end

