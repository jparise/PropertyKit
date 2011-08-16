/*
 * PropertyKit.h
 * http://github.com/jparise/PropertyKit
 *
 * Copyright 2011, Jon Parise. All rights reserved.
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#include <objc/runtime.h>

#ifndef _PROPERTYKIT_H_
#define _PROPERTYKIT_H_

#ifdef __cplusplus
extern "C" {
#endif

#pragma mark - Property Introspection

typedef enum
{
    PKPropertySetterSemanticsAssign,
    PKPropertySetterSemanticsRetain,
    PKPropertySetterSemanticsCopy,
} PKPropertySetterSemantics;

typedef struct
{
    PKPropertySetterSemantics setterSemantics;
    SEL customGetter;
    SEL customSetter;

    unsigned int isReadOnly:1;
    unsigned int isNonAtomic:1;
    unsigned int isDynamic:1;
    unsigned int isWeakReference:1;
    unsigned int isEligibleForGarbageCollection:1;

    char ivarName[64];
    char typeEncoding[64];
} PKPropertyAttributes;

PKPropertyAttributes PKPropertyAttributesMake(objc_property_t property);

@interface PKProperty : NSObject
{
@private
    objc_property_t _property;
    PKPropertyAttributes _attributes;
}

@property (nonatomic,readonly) objc_property_t property;
@property (nonatomic,readonly) PKPropertyAttributes attributes;
@property (nonatomic,readonly) PKPropertySetterSemantics setterSemantics;
@property (nonatomic,readonly) SEL customGetter;
@property (nonatomic,readonly) SEL customSetter;
@property (nonatomic,readonly) BOOL isReadOnly;
@property (nonatomic,readonly) BOOL isNonAtomic;
@property (nonatomic,readonly) BOOL isDynamic;
@property (nonatomic,readonly) BOOL isWeakReference;
@property (nonatomic,readonly) BOOL isEligibleForGarbageCollection;
@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSString *typeEncoding;
@property (nonatomic,readonly) NSString *ivarName;

+ (id)propertyWithObjCProperty:(objc_property_t)property;
+ (id)propertyWithName:(NSString *)name forClass:(Class)cls;

- (id)initWithObjCProperty:(objc_property_t)property;
- (id)initWithName:(NSString *)name forClass:(Class)cls;

@end

#pragma mark - Property Observing

@interface NSObject (PropertyKitObserving)
- (void)observeValueForProperty:(NSString *)name value:(id)value;
@end

@interface NSObject (PropertyKitObservingRegistration)
+ (void)addObservedProperty:(NSString *)name;
@end
    
#ifdef __cplusplus
} // extern "C"
#endif

#endif // _PROPERTYKIT_H_
