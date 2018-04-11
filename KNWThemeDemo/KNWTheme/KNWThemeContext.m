//
//  KNWThemeContext.m
//  KNWTheme
//
//  Created by William on 12/29/15.
//  Copyright © 2015 coppercash. All rights reserved.
//

#import "KNWThemeContext.h"

#import "KNWThemedInvocation.h"

#import <objc/runtime.h>

@interface NSObject (KNWThemableObjectProxy)
@property (readonly) NSMutableArray *knw_invocations;
@end

@implementation KNWThemeContext
@dynamic theme;

+ (instancetype)defaultThemeContext
{
    KNWThemeContext static
    *_instance = nil;
    dispatch_once_t static
    _predicate;
    dispatch_once(&_predicate, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _themableObjects = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return self;
}

#pragma mark - Theme

- (void)setTheme:(id<NSCopying>)theme
{
    _theme = theme;
    
    for (NSObject *object in _themableObjects) {
        for (KNWThemedInvocation *invocation in object.knw_invocations) {
            [invocation invokeWithTarget:object];
        }
    }
}

- (id<NSCopying>)theme
{
    return _theme;;
}

#pragma mark -

- (void)registerThemableObject:(NSObject *)object
                withInvocation:(KNWThemedInvocation *)invocation
{
    NSParameterAssert(object);
    NSParameterAssert(invocation);
    
    // Context weakly refers the target object
    //
    if (NO == [_themableObjects containsObject:object]) {
        [_themableObjects addObject:object];
    }
    
    // Keep reference of retained invocation
    //
    [object.knw_invocations addObject:invocation];
}

@end

@implementation NSObject (KNWThemableObjectProxy)

- (NSMutableArray *)knw_invocations {
    NSMutableArray
    *invocations = objc_getAssociatedObject(self, _cmd);
    if (nil == invocations) {
        objc_setAssociatedObject(self,
                                 _cmd,
                                 (invocations = [[NSMutableArray alloc] init]),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return invocations;
}

@end
