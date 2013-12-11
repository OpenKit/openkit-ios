//
//  OKAchievement.h
//  OpenKit
//
//  Created by Suneet Shah on 12/10/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKAchievement : NSObject

@property (nonatomic) int achievementID, points, goal, progress;
@property (nonatomic, strong) NSString *name, *description, *lockedIconURL, *unlockedIconURL;

-(id)initFromJSON:(NSDictionary*)jsonDict;

@end
