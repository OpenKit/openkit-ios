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

+(void)sendPushChallengewithScorePostResponseJSON:(id)responseObject withPreviousScore:(OKScore*)previousScore
{
    OKLog(@"Trying to send push challenge.");
    
    if([OKLocalUser currentUser] == nil) {
        OKLog(@"Can't issue push challenge without current OKUser");
        return;
    }

    
    // See if the score was a top score
    BOOL wasTopScore = [OKHelper getBOOLFrom:responseObject key:@"is_users_best"];
    if(!wasTopScore) {
        OKLog(@"Score submitted was not users best");
        return;
    }
    
    OKScore *topScore = [[OKScore alloc] initWithDictionary:responseObject];
    if(!topScore ) {
        OKLog(@"Score JSON wasn't valid, couldn't create score");
        return;
    }
    
    OKLeaderboard *leaderboard;
    NSDictionary *leaderboardJSON = [OKHelper getNSDictionaryFrom:responseObject key:@"leaderboard"];
    
    if(leaderboardJSON != nil) {
        leaderboard = [[OKLeaderboard alloc] initWithDictionary:leaderboardJSON];
    } else {
        OKLog(@"Didn't get leaderboard JSON in response, can't issue push challenge");
        return;
    }
    
    // Get the social scores
    [leaderboard getSocialScoresForTimeRange:0 completion:^(NSArray *scores, NSError *error) {
        
        if(!error && scores != nil) {
            [self issuePushChallengeforLeaderboard:leaderboard withUserTopScore:topScore withPreviousScore:previousScore withFriendsScores:scores];
        } else {
            OKLog(@"Didn't get friends scores, so not sending push challenge");
        }
    }];
}


// Given a leaderboard, player top score, and list of social scores, figures out which OKScore objects (and their OKUsers) get sent
// a challenge
+(void)issuePushChallengeforLeaderboard:(OKLeaderboard*)leaderboard withUserTopScore:(OKScore*)topScore withPreviousScore:(OKScore*)previousScore withFriendsScores:(NSArray*)friendsScores
{
    // If there was no previous score stored, create a previous score with the maximum allowed value for a score
    // type based on the leaderboard sort type. 
    if(previousScore == nil)
    {
        previousScore = [[OKScore alloc] init];
        
        if([leaderboard sortType] == OKLeaderboardSortTypeHighValue) {
            previousScore.scoreValue = 0;
        } else {
            previousScore.scoreValue = INT64_MAX;
        }
    }
    
    OKLog(@"Sorting social scores to figure out which will get a challenge");
    OKLog(@"Player's previous top score is: %lld, and new top score is: %lldd", [previousScore scoreValue], [topScore scoreValue]);
    
    
    // Go through the list of friends' scores, and find scores which are < playerTopScore && > previousScore
    // If there was no previous score, the above code sets the "previous score" to the min and max values depending
    // on sort type so that all friends below the player's top score get a push
    
    NSMutableArray *scoresToSendPushTo = [[NSMutableArray alloc] init];
    for(OKScore *score in friendsScores) {
        
        if([leaderboard sortType] == OKLeaderboardSortTypeHighValue) {
            if([score scoreValue] < [topScore scoreValue] && [score scoreValue] > [previousScore scoreValue]) {
                [scoresToSendPushTo addObject:score];
            }
        } else {
            if([score scoreValue] > [topScore scoreValue] && [score scoreValue] < [previousScore scoreValue]) {
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
    OKLog(@"Doing the network call to issue push challenge");
    OKLog(@"Sending challenge to %lu users", (unsigned long)[scores count]);
    
    NSMutableArray *friends_receiver_ids = [[NSMutableArray alloc] init];
    
    for(OKScore *friend_score in scores) {
        [friends_receiver_ids addObject:[[friend_score user] userID]];
    }
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            friends_receiver_ids, @"receiver_ids",
                            [[OKLocalUser currentUser] userID], @"sender_id",
                            [OKUtils createUUID], @"challenge_uuid",
                            [OKUtils sqlStringFromDate:[NSDate date]], @"client_created_at",
                            nil];
    NSString *path = [NSString stringWithFormat:@"/leaderboards/%li/challenges", (long)leaderboard.leaderboardID];
    
    [OKNetworker postToPath:path
                 parameters:params
                 completion:^(OKResponse *response)
    {
        NSError *error = [response error];
        if(error) {
            OKLog(@"Error from server is: %@", error);
        }
    }];
}

@end
