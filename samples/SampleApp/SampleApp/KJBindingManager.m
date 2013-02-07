//
//  KJBindingManager.m
//  KJSimpleBinding
//
// Copyright (C) 2012 Kristopher Johnson
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "KJBindingManager.h"


typedef id (^KJTransformBlock)(id value);


// The KJBinding class is used internally by KJBindingManager.
// It should be considered a private implementation detail.

@interface KJBinding : NSObject

@property (nonatomic, assign) NSObject *observer;
@property (nonatomic, copy) NSString *observerKeyPath;
@property (nonatomic, assign) NSObject *subject;
@property (nonatomic, copy) NSString *subjectKeyPath;
@property (nonatomic, copy) KJTransformBlock transformBlock;

- (void)activate;

- (void)deactivate;

@end

@implementation KJBinding

@synthesize observer = _observer;
@synthesize observerKeyPath = _observerKeyPath;
@synthesize subject = _subject;
@synthesize subjectKeyPath = _subjectKeyPath;
@synthesize transformBlock = _transformBlock;

- (void)dealloc {
    [_observerKeyPath release];
    [_subjectKeyPath release];
    [_transformBlock release];
    [super dealloc];
}

- (void)activate {
    [_subject addObserver:self
               forKeyPath:_subjectKeyPath
                  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
                  context:NULL];
}

- (void)deactivate {
    [_subject removeObserver:self forKeyPath:_subjectKeyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    id newValue = [change valueForKey:NSKeyValueChangeNewKey];
    if (_transformBlock) {
        newValue = _transformBlock(newValue);
    }
    [_observer setValue:newValue forKeyPath:_observerKeyPath];
}

@end


@implementation KJBindingManager

- (id)init {
    self = [super init];
    if (self) {
        _bindings = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    if (_isEnabled) {
        // Disconnect all the observers before we release the bindings
        [self disable];
    }
    [_bindings release];
    [super dealloc];
}

- (void)bindObserver:(NSObject *)observer
             keyPath:(NSString *)observerKeyPath
           toSubject:(NSObject *)subject
             keyPath:(NSString *)subjectKeyPath
{
    [self bindObserver:observer
               keyPath:observerKeyPath
             toSubject:subject
               keyPath:subjectKeyPath
    withValueTransform:nil];
}

- (void)bindObserver:(NSObject *)observer
             keyPath:(NSString *)observerKeyPath
           toSubject:(NSObject *)subject
             keyPath:(NSString *)subjectKeyPath
  withValueTransform:(id (^)(id value))transformBlock
{
    KJBinding *binding = [[KJBinding alloc] init];
    
    binding.observer = observer;
    binding.observerKeyPath = observerKeyPath;
    binding.subject = subject;
    binding.subjectKeyPath = subjectKeyPath;
    binding.transformBlock = transformBlock;
    
    [_bindings addObject:binding];
    
    if (_isEnabled) {
        [binding activate];
    }
    
    [binding release];    
}

- (void)enable {
    if (!_isEnabled) {
        for (KJBinding *binding in _bindings) {
            [binding activate];
        }
    }
    else {
        NSLog(@"WARNING: KJBindingManger: attempted to enable already-enabled instance");
    }
    _isEnabled = YES;
}

- (void)disable {
    if (_isEnabled) {
        for (KJBinding *binding in _bindings) {
            [binding deactivate];
        }
    }
    else {
        NSLog(@"WARNING: KJBindingManger: attempted to disable already-disabled instance");
    }
    _isEnabled = NO;
}

- (BOOL)isEnabled {
    return _isEnabled;
}

- (void)removeAllBindings {
    if (_isEnabled) {
        for (KJBinding *binding in _bindings) {
            [binding deactivate];
        }        
    }
    [_bindings removeAllObjects];
}

@end
