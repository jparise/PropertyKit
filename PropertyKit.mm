/*
 * PropertyKit.mm
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

#import "PropertyKit.h"

#include <CoreFoundation/CFNumber.h>
#include <objc/message.h>

#pragma mark - Property Introspection -

@implementation PKProperty

@synthesize property = _property, attributes = _attributes;
@dynamic setterSemantics, customGetter, customSetter;
@dynamic isReadOnly, isNonAtomic, isDynamic, isWeakReference, isEligibleForGarbageCollection;
@dynamic name, typeEncoding, ivarName;

static SEL _PKSelectorForString(const char *pString, const size_t length)
{
    char selectorName[128];
    strlcpy(selectorName, pString, MIN(length + 1, sizeof(selectorName)));
    return sel_registerName(selectorName);
}

PKPropertyAttributes PKPropertyAttributesMake(objc_property_t property)
{
    const char * const pAttributes = property_getAttributes(property);
    const char * const pAttributesEnd = pAttributes + strlen(pAttributes);

    PKPropertyAttributes attributes;
    bzero(&attributes, sizeof(attributes));

    for (const char *pAttribute = pAttributes; pAttribute < pAttributesEnd;)
    {
        // Find the last character of the current attribute substring.
        const char *pAttributeEnd = strchr(pAttribute, ',');
        if (pAttributeEnd == NULL)
            pAttributeEnd = pAttributesEnd;

        const char descriptor = *pAttribute++;
        const size_t length = pAttributeEnd - pAttribute;

        switch (descriptor)
        {
            case 'T':
                strncpy(attributes.typeEncoding, pAttribute, MIN(length, sizeof(attributes.typeEncoding) - 1));
                break;

            case 'R':
                attributes.isReadOnly = 1;
                break;

            case 'C':
                attributes.setterSemantics = PKPropertySetterSemanticsCopy;
                break;

            case '&':
                attributes.setterSemantics = PKPropertySetterSemanticsRetain;
                break;

            case 'N':
                attributes.isNonAtomic = 1;
                break;

            case 'G':
                attributes.customGetter = _PKSelectorForString(pAttribute, length);
                break;

            case 'S':
                attributes.customSetter = _PKSelectorForString(pAttribute, length);
                break;

            case 'D':
                attributes.isDynamic = 1;
                break;

            case 'W':
                attributes.isWeakReference = 1;
                break;

            case 'P':
                attributes.isEligibleForGarbageCollection = 1;
                break;

            case 'V':
                strncpy(attributes.ivarName, pAttribute, MIN(length, sizeof(attributes.ivarName) - 1));
                break;
        }

        pAttribute = pAttributeEnd + 1;
    }

    return attributes;
}

#pragma mark Initializers

+ (id)propertyWithObjCProperty:(objc_property_t)property
{
    return [[[self alloc] initWithObjCProperty:property] autorelease];
}

- (id)initWithObjCProperty:(objc_property_t)property
{
    if ((self = [super init]))
    {
        _property = property;
        _attributes = PKPropertyAttributesMake(property);
    }

    return self;    
}

+ (id)propertyWithName:(NSString *)name forClass:(Class)cls
{
    return [[[self alloc] initWithName:name forClass:cls] autorelease];
}

- (id)initWithName:(NSString *)name forClass:(Class)cls
{
    objc_property_t property = class_getProperty(cls, [name UTF8String]);
    if (!property)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Unrecognized property '%@' for class %@", name, cls];
        return nil;
    }

    return [self initWithObjCProperty:property];
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[PKProperty class]])
    {
        return (((PKProperty *)object)->_property == _property);
    }

    return NO;
}

- (NSUInteger)hash
{
    return (NSUInteger)(uintptr_t)_property;
}

- (NSString *)description
{
    NSMutableString *attributes = [NSMutableString string];
    if (self.isNonAtomic)   [attributes appendString:@"nonatomic,"];
    if (self.isReadOnly)    [attributes appendString:@"readonly,"];
    if (self.customGetter)  [attributes appendFormat:@"getter=%s", sel_getName(self.customGetter)];
    if (self.customSetter)  [attributes appendFormat:@"setter=%s", sel_getName(self.customSetter)];

    switch (self.setterSemantics)
    {
        case PKPropertySetterSemanticsAssign:
            [attributes appendString:@"assign"];
            break;

        case PKPropertySetterSemanticsRetain:
            [attributes appendString:@"retain"];
            break;

        case PKPropertySetterSemanticsCopy:
            [attributes appendString:@"copy"];
            break;
    }

    return [NSString stringWithFormat:@"<%@ (%@) '%@' %@ = %@>",
            NSStringFromClass([self class]), attributes, self.typeEncoding,
            self.name, self.ivarName];
}

#pragma mark Attributes

- (PKPropertySetterSemantics)setterSemantics
{
    return _attributes.setterSemantics;
}

- (SEL)customGetter
{
    return _attributes.customGetter;
}

- (SEL)customSetter
{
    return _attributes.customSetter;
}

- (BOOL)isReadOnly
{
    return _attributes.isReadOnly;
}

- (BOOL)isNonAtomic
{
    return _attributes.isNonAtomic;
}

- (BOOL)isDynamic
{
    return _attributes.isDynamic;
}

- (BOOL)isWeakReference
{
    return _attributes.isWeakReference;
}

- (BOOL)isEligibleForGarbageCollection
{
    return _attributes.isEligibleForGarbageCollection;
}

- (NSString *)name
{
    return [NSString stringWithUTF8String:property_getName(_property)];
}

- (NSString *)typeEncoding
{
    return [NSString stringWithUTF8String:_attributes.typeEncoding];
}

- (NSString *)ivarName
{
    return [NSString stringWithUTF8String:_attributes.ivarName];
}

@end

#pragma mark - Property Observing -

#pragma mark CFNumberTraits

template <typename T>
struct CFNumberTraits
{
    static const CFNumberType type = kCFNumberMaxType;
};

template <>
struct CFNumberTraits<char>
{ 
    static const CFNumberType type = kCFNumberCharType;
};

template <>
struct CFNumberTraits<int>
{ 
    static const CFNumberType type = kCFNumberIntType;
};

template <>
struct CFNumberTraits<SInt8>
{ 
    static const CFNumberType type = kCFNumberSInt8Type;
};

template <>
struct CFNumberTraits<SInt16>
{ 
    static const CFNumberType type = kCFNumberSInt16Type;
};

template <>
struct CFNumberTraits<SInt32>
{ 
    static const CFNumberType type = kCFNumberSInt32Type;
};

template <>
struct CFNumberTraits<SInt64>
{ 
    static const CFNumberType type = kCFNumberSInt64Type;
};

template <>
struct CFNumberTraits<Float32>
{ 
    static const CFNumberType type = kCFNumberFloat32Type;
};

template <>
struct CFNumberTraits<Float64>
{ 
    static const CFNumberType type = kCFNumberFloat64Type;
};

#pragma mark Generic Helper Functions

static objc_property_t _PKPropertyFromSetter(Class cls, SEL setter)
{
    const char * const pSetterName = sel_getName(setter);
    const size_t length = strlen(pSetterName) - sizeof("set");

    char propertyName[128];
    strlcpy(propertyName, pSetterName + 3, MIN(length + 1, sizeof(propertyName)));
    propertyName[0] = tolower(propertyName[0]);

    return class_getProperty(cls, propertyName);
};

template <typename T>
static __inline__ T _PKGetIvar(id obj, Ivar ivar)
{
    // (T)(uintptr_t)object_getIvar(obj, ivar);
    return *(T *)((uintptr_t)obj + ivar_getOffset(ivar));
}

template <typename T>
static __inline__ void _PKSetIvar(id obj, Ivar ivar, T value)
{
    // object_setIvar(obj, ivar, (id)value);
    *(T *)((uintptr_t)obj + ivar_getOffset(ivar)) = value;
}

static __inline__ void _PKNotifyPropertyValue(id self, const char *pName, id value)
{
    CFStringRef name = CFStringCreateWithCString(kCFAllocatorDefault, pName, kCFStringEncodingUTF8);
    [self observeValueForProperty:(NSString *)name value:value];
    CFRelease(name);
}

#pragma mark Setter Implementations

template <typename T>
static void _PKNumericSetter(id self, SEL _cmd, T newValue)
{
    Class cls = object_getClass(self);
    objc_property_t property = _PKPropertyFromSetter(cls, _cmd);
    PKPropertyAttributes attributes = PKPropertyAttributesMake(property);

    Ivar ivar = class_getInstanceVariable(cls, attributes.ivarName);
    if (ivar)
    {
        T oldValue = _PKGetIvar<T>(self, ivar);
        if (newValue != oldValue)
        {
            _PKSetIvar(self, ivar, newValue);

            CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, CFNumberTraits<T>::type, &newValue);            
            _PKNotifyPropertyValue(self, property_getName(property), (id)number);
            CFRelease(number);
        }
    }
}

static void _PKObjectSetter(id self, SEL _cmd, id newObject)
{
    Class cls = object_getClass(self);
    objc_property_t property = _PKPropertyFromSetter(cls, _cmd);
    PKPropertyAttributes attributes = PKPropertyAttributesMake(property);

    BOOL retainNewValue, copyNewValue, releaseOldValue;
    switch (attributes.setterSemantics)
    {
        case PKPropertySetterSemanticsAssign:
            retainNewValue  = NO;
            copyNewValue    = NO;
            releaseOldValue = NO;
            break;

        case PKPropertySetterSemanticsRetain:
            retainNewValue  = YES;
            copyNewValue    = NO;
            releaseOldValue = YES;
            break;

        case PKPropertySetterSemanticsCopy:
            retainNewValue  = NO;
            copyNewValue    = YES;
            releaseOldValue = YES;
            break;
    }

    Ivar ivar = class_getInstanceVariable(cls, attributes.ivarName);
    if (ivar)
    {
        id oldObject = object_getIvar(self, ivar);
        if (newObject != oldObject)
        {
            if (retainNewValue)
            {
                newObject = [newObject retain];
            }
            else if (copyNewValue)
            {
                newObject = [newObject copy];
            }

            object_setIvar(self, ivar, newObject);
            _PKNotifyPropertyValue(self, property_getName(property), newObject);

            if (releaseOldValue)
            {
                [oldObject release];
            }
        }
    }
}

#pragma mark Registration

@implementation NSObject (PropertyKitObservingRegistration)

+ (void)addObservedProperty:(NSString *)name
{
    PKProperty *property = [PKProperty propertyWithName:name forClass:self];
    if (!property) return;

    if (property.customSetter)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Properties with a custom setter cannot be observed"];
        return;
    }

    if (property.isDynamic)
    {
        [NSException raise:NSInvalidArgumentException
                    format:@"Dynamic properies cannot be observed"];
        return;
    }

    NSString *setterName = [NSString stringWithFormat:@"set%@%@:",
                            [[name substringToIndex:1] uppercaseString],
                            [name substringFromIndex:1]];
    NSString *signature = [NSString stringWithFormat:@"v@:%@", property.typeEncoding];
    const char * const typeEncoding = [property.typeEncoding UTF8String];

    IMP imp = NULL;
    switch (typeEncoding[0])
    {
        case _C_ID:
            imp = (IMP)&_PKObjectSetter;
            break;

        case _C_CHR:
            imp = (IMP)(void (*)(id, SEL, char))&_PKNumericSetter<char>;
            break;

        case _C_UCHR:
            imp = (IMP)(void (*)(id, SEL, unsigned char))&_PKNumericSetter<unsigned char>;
            break;

        case _C_SHT:
            imp = (IMP)(void (*)(id, SEL, short))&_PKNumericSetter<short>;
            break;

        case _C_USHT:
            imp = (IMP)(void (*)(id, SEL, unsigned short))&_PKNumericSetter<unsigned short>;
            break;

        case _C_INT:
            imp = (IMP)(void (*)(id, SEL, int))&_PKNumericSetter<int>;
            break;

        case _C_UINT:
            imp = (IMP)(void (*)(id, SEL, unsigned int))&_PKNumericSetter<unsigned int>;
            break;

        case _C_LNG:
            imp = (IMP)(void (*)(id, SEL, long))&_PKNumericSetter<long>;
            break;

        case _C_ULNG:
            imp = (IMP)(void (*)(id, SEL, unsigned long))&_PKNumericSetter<unsigned long>;
            break;

        case _C_LNG_LNG:
            imp = (IMP)(void (*)(id, SEL, long long))&_PKNumericSetter<long long>;
            break;

        case _C_ULNG_LNG:
            imp = (IMP)(void (*)(id, SEL, unsigned long long))&_PKNumericSetter<unsigned long long>;
            break;

        case _C_FLT:
            imp = (IMP)(void (*)(id, SEL, float))&_PKNumericSetter<float>;
            break;

        case _C_DBL:
            imp = (IMP)(void (*)(id, SEL, double))&_PKNumericSetter<double>;
            break;

        default:
            [NSException raise:NSInvalidArgumentException
                        format:@"Unsupported property type encoding: %s", typeEncoding];
            return;
    }

    if (!class_replaceMethod(self, NSSelectorFromString(setterName), imp, [signature UTF8String]))
    {
        [NSException raise:NSInternalInconsistencyException
                    format:@"Failed to replace property setter: %@ %@", self, setterName];
    }
}

@end
