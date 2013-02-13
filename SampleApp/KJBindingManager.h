//
//  KJBindingManager.h
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

#import <Foundation/Foundation.h>

// Maintains a set of KVO observers, automatically copying values when they change

@interface KJBindingManager : NSObject {
@private
    NSMutableArray *_bindings;
    BOOL _isEnabled;
}

// Bind an observer's value specified by key path to a subject object's value.
//
// Neither observer nor subject are retained; it is the responsibility of the
// caller to ensure that the objects are not deallocated for the duration
// of the binding.
//
// The observer must be KVC-compliant for the observerKeyPath.
//
// The subject must be KVO-compliant for the subjectKeyPath
- (void)bindObserver:(NSObject *)observer
             keyPath:(NSString *)observerKeyPath
           toSubject:(NSObject *)subject
             keyPath:(NSString *)subjectKeyPath;

// Bind an observer's value specified by key path to a subject object's value,
// transformed using the specified block.
//
// Neither observer nor subject are retained; it is the responsibility of the
// caller to ensure that the objects are not deallocated for the duration
// of the binding.
//
// The observer must be KVC-compliant for the observerKeyPath.
//
// The subject must be KVO-compliant for the subjectKeyPath
- (void)bindObserver:(NSObject *)observer
             keyPath:(NSString *)observerKeyPath
           toSubject:(NSObject *)subject
             keyPath:(NSString *)subjectKeyPath
  withValueTransform:(id(^)(id value))transformBlock;

// Return YES if the binding manager is enabled; NO if not.
// A binding manager is not enabled until its -enable method is called.
- (BOOL)isEnabled;

// Activate binding behavior.
// This will immediately copy current values of subjects to the observers, and
// changes will be propagated.
- (void)enable;

// Stop binding behavior.
- (void)disable;

// Clear list of bindings
- (void)removeAllBindings;

@end
