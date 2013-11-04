//
//  OKFileUtil.m
//  OpenKit
//
//  Created by Louis Zell on 8/21/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKFileUtil.h"
#import "OKUtils.h"
#import "OKMacros.h"
#import "OKManager.h"


@implementation OKFileUtil

+ (BOOL)createDir:(NSString *)path
{
    return [self createDir:path skipBackup:NO];
}


+ (BOOL)createDir:(NSString *)path skipBackup:(BOOL)skipBackup
{
    NSError *err = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err]) {
        OKLogErr(@"%@", err.localizedDescription);
        return NO;
    }

    if (skipBackup) {
        NSURL *u = [NSURL fileURLWithPath:path];
        if (![u setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&err]) {
            OKLogErr(@"Error excluding %@ from backup %@", u.lastPathComponent, err.localizedDescription);
        }
    }
    return YES;
}


+ (NSString*)localOnlyCachePath
{
    NSString *p1, *p2;
    p1 = [self applicationSupportPath];
    if (p1 == nil)
        return nil;

    p2 = [p1 stringByAppendingPathComponent:@"OpenKit"];
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:p2 isDirectory:&isDir]) {
        if (![self createDir:p2 skipBackup:YES]) {
            OKLogErr(@"Could not create local only cache directory.");
        }
    }
    return p2;
}


+ (NSString*)localOnlyCachePath:(NSString*)filename
{
    return [[OKFileUtil localOnlyCachePath] stringByAppendingPathComponent:filename];
}


+ (NSString*)applicationSupportPath
{
    NSArray *arr = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *p = [arr lastObject];
    BOOL isDir;
    if (![[NSFileManager defaultManager] fileExistsAtPath:p isDirectory:&isDir]) {
        if (![self createDir:p]) {
            OKLogErr(@"Could not create application support directory.");
            p = nil;
        }
    }
    return p;
}


+ (id)readSecureFile:(NSString*)path
{
    NSParameterAssert(path);

    NSDictionary *packet;
    NSData *archive = [NSData dataWithContentsOfFile:path];
    if(!archive)
        return nil;
    
    NSData *decrypt = [[[OKManager sharedManager] cryptor] decryptData:archive];
    if(!decrypt) {
        OKLogErr(@"OKFileUtils: Error in secure file. Bad encryption.");
        goto error;
    }

    packet = [NSKeyedUnarchiver unarchiveObjectWithData:decrypt];
    if(![packet isKindOfClass:[NSDictionary class]]) {
        OKLogErr(@"OKFileUtils: Fail secure file. Bad format.");
        goto error;
    }

    // validate path
    if(![packet[@"path"] isEqualToString:[path lastPathComponent]]) {
        OKLogErr(@"OKFileUtils: Fail secure file. Path doesn't match.");
        goto error;
    }
    
    return packet[@"data"];


error:
    // If security fails, we remove the file. It was modified.
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    return nil;
}


+ (BOOL)writeOnFileSecurely:(id)object path:(NSString*)path
{
    NSParameterAssert(path);
    NSParameterAssert(object);

    NSDictionary *packet = @{@"path": [path lastPathComponent],
                             @"data": object };

    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:packet];
    NSData *encrypt = [[[OKManager sharedManager] cryptor] encryptData:archive];
    return [encrypt writeToFile:path atomically:YES];
}

@end
