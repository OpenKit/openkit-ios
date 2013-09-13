//
//  OKChallenge.m
//  OpenKit
//
//  Created by Suneet Shah on 9/13/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKChallenge.h"
#import "OKUser.h"
#import "OKScore.h"
#import "OKLeaderboard.h"
#import "OKFacebookUtilities.h"
#import "OKHelper.h"
#import "OKUtils.h"
#import "OKMacros.h"
#import "OKNetworker.h"

@implementation OKChallenge

+(void)sendPushChallengewithScorePostResponseJSON:(id)responseObject
{
    OKLog(@"Trying to send push challenge. Score response JSON: %@", responseObject);
    
    if([OKUser currentUser] == nil) {
        OKLog(@"Can't issue push challenge without current OKUser");
        return;
    } else if ([[OKUser currentUser] fbUserID] == nil) {
        OKLog(@"Cant issue push challenge without user having fbID");
        return;
    } else if (![OKFacebookUtilities isFBSessionOpen]) {
        OKLog(@"Can't issue push challenge without open FB session ");
        return;
    }
    
    // See if the score was a top score
    BOOL wasTopScore = [OKHelper getBOOLSafeForKey:@"is_users_best" fromJSONDictionary:responseObject];
    if(!wasTopScore) {
        OKLog(@"Score submitted was not users best");
        return;
    }
    
    OKScore *topScore = [[OKScore alloc] initFromJSON:responseObject];
    if(!topScore ) {
        OKLog(@"Score JSON wasn't valid, couldn't create score");
        return;
    }
    
    OKLeaderboard *leaderboard;
    NSDictionary *leaderboardJSON = [OKHelper getNSDictionarySafeForKey:@"leaderboard" fromJSONDictionary:responseObject];
    
    if(leaderboardJSON != nil) {
        leaderboard = [[OKLeaderboard alloc] initFromJSON:leaderboardJSON];
    } else {
        OKLog(@"Didn't get leaderboard JSON in response, can't issue push challenge");
        return;
    }
    
    // Get the social scores
    [leaderboard getFacebookFriendsScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        
        if(!error && scores != nil) {
            [self issuePushChallengeforLeaderboard:leaderboard withUserTopScore:topScore withFriendsScores:scores];
        } else {
            OKLog(@"Didn't get friends scores, so not sending push challenge");
        }
    }];
}

// Given a leaderboard, player top score, and list of social scores, figures out which OKScore objects (and their OKUsers) get sent
// a challenge
+(void)issuePushChallengeforLeaderboard:(OKLeaderboard*)leaderboard withUserTopScore:(OKScore*)topScore withFriendsScores:(NSArray*)friendsScores
{
    NSMutableArray *scoresToSendPushTo = [[NSMutableArray alloc] init];
    
    for(int x = 0; x < [friendsScores count]; x++)
    {
        OKScore *score = [friendsScores objectAtIndex:x];
        
        if([leaderboard sortType] == OKLeaderboardSortTypeHighValue) {
            if([score scoreValue] < [topScore scoreValue]) {
                [scoresToSendPushTo addObject:score];
            }
        } else {
            if([score scoreValue] > [topScore scoreValue]) {
                [scoresToSendPushTo addObject:score];
            }
        }
    }
    
    if([scoresToSendPushTo count] > 0) {
        [self issuePushChallengeForListOfOKScores:scoresToSendPushTo andLeaderboard:leaderboard];
    } else {
        OKLog(@"Not sending push because top score was not actually better than any friends scores");
    }
}

// Actually issue the challenge
+(void)issuePushChallengeForListOfOKScores:(NSArray*)scores andLeaderboard:(OKLeaderboard*)leaderboard
{
    // DO THE NETWORK CALL
    NSArray *friends = [[NSUserDefaults standardUserDefaults] objectForKey:@"okfriendsList"];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            friends, @"receiver_ids",
                            [[OKUser currentUser] OKUserID], @"sender_id",
                            [OKUtils createUUID], @"challenge_uuid",
                            [OKUtils sqlStringFromDate:[NSDate date]], @"client_created_at",
                            nil];
    NSString *p = [NSString stringWithFormat:@"leaderboards/%i/challenges", leaderboard.OKLeaderboard_id];
    [OKNetworker postToPath:p parameters:params handler:^(id responseObject, NSError *error) {
        // blah blah blah.
    }];
    
}


@end
