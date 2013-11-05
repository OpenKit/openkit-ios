//
//  OKGame.m
//  OKClient
//
//  Created by Manu Martinez-Almeida
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#import "OKGame.h"
#import "OKUtils.h"
#import "OKMacros.h"


@interface OKGame () 
@property(nonatomic, strong) NSMutableArray *instants;
@end



@interface OKInstant : NSObject<NSCoding>
@property(nonatomic, readonly) double timestamp;
@property(nonatomic, readonly) id data;

- (id)initWithObject:(id)data;

@end


@interface OKReplay ()
{
    NSInteger _index;
    NSArray *_instants;
    BOOL _running;
}
- (id)initWithGame:(OKGame*)game;

@end


#pragma mark -

@implementation OKInstant

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _data = [aDecoder decodeObjectForKey:@"d"];
        _timestamp = [aDecoder decodeDoubleForKey:@"t"];
    }
    return self;
}


- (id)initWithObject:(id)data
{
    self = [super init];
    if (self) {
        _timestamp = [OKUtils timestamp];
        _data = data;
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_data forKey:@"d"];
    [aCoder encodeDouble:_timestamp forKey:@"t"];
}

@end


@implementation OKGame

- (id)initWithDictionary:(NSDictionary*)dict
{
    self = [super init];
    if (self) {
        _contextData = dict;
        _instants = [[NSMutableArray alloc] initWithCapacity:100];
    }
    return self;
}


-(void)catchInstant:(id)obj
{
    OKInstant *instant = [[OKInstant alloc] initWithObject:obj];
    [_instants addObject:instant];
}


- (double)playingTime
{
    if([_instants count] < 2)
        return 0;

    OKInstant *start = _instants[0];
    OKInstant *end = [_instants lastObject];
    
    return (end.timestamp - start.timestamp);
}


- (OKReplay*)replay
{
    return [[OKReplay alloc] initWithGame:self];
}


- (void)replayWithBlock:(OKReplayBlock)block
{
    [[self replay] replayWithBlock:block completion:nil];
}


- (NSDictionary*)archive
{
    NSAssert(_instants, @"Instants can not be nil.");

    return @{@"context": OK_NO_NIL(_contextData),
             @"instants": _instants };
}

@end


@implementation OKReplay

- (id)initWithGame:(OKGame*)game
{
    NSParameterAssert(game);

    self = [super init];
    if (self) {
        _instants = game.instants;
        _speed = 1.0f;
        _running = NO;

        [self setProgress:0];
    }
    return self;
}


- (void)setProgress:(double)progress
{
    NSParameterAssert(progress <= 1.0f);
    _index = (NSUInteger)(progress * [_instants count]);
}


- (void)setSpeed:(double)speed
{
    if(speed != 0)
        _speed = speed;
}


- (void)replayWithBlock:(OKReplayBlock)block completion:(OKBlock)handler
{
    NSParameterAssert(block);

    _index = 0;
    _replayHandler = block;
    _completionHandler = handler;
    [self setProgress:0];
    [self start];
}


- (void)start
{
    if(!_running) {
        _running = YES;
        [self next];
    }
}


- (void)stop
{
    _running = NO;
}


- (void)step
{
    [self stop];
    [self next];
}


- (void)next
{
    if(_index >= 0 && _index < [_instants count]) {

        double step = 0;

        OKInstant *current = _instants[_index];
        if(_speed > 0) {
            if(_index > 1) {
                OKInstant *previous = _instants[_index-1];
                step = (current.timestamp - previous.timestamp);
            }
            _index++;
        }else{
            if(_index < ([_instants count]-1)) {
                OKInstant *previous = _instants[_index+1];
                step = (previous.timestamp - current.timestamp);
            }
            _index--;
        }

        step /= fabs(_speed);
        double time = _index/(double)[_instants count];
        _replayHandler(time, step, [current data]);

        if(_running) {
            dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW,(long long)(step * NSEC_PER_SEC));
            dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                [self next];
            });
        }
    }else{
        [self stop];
        if(_completionHandler)
            _completionHandler();
    }
}

@end
