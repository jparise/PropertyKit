/*
 * PropertyKitTests.m
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

#import "PropertyKitTests.h"
#import "PropertyKit.h"

#pragma mark - Test Object

@interface PKTestObject : NSObject
{
@private
    NSMutableArray * _arrayValue;
}

@property (nonatomic, retain) NSMutableDictionary * observedValues;

@property (assign)           BOOL       boolValue;
@property (nonatomic,assign) float      floatValue;
@property (nonatomic,assign) double     doubleValue;
@property (nonatomic,assign) NSInteger  integerValue;
@property (nonatomic,assign) NSUInteger uintegerValue;
@property (nonatomic,assign) int8_t     int8Value;
@property (nonatomic,assign) int16_t    int16Value;
@property (nonatomic,assign) int32_t    int32Value;
@property (nonatomic,assign) int64_t    int64Value;
@property (nonatomic,assign) uint8_t    uint8Value;
@property (nonatomic,assign) uint16_t   uint16Value;
@property (nonatomic,assign) uint32_t   uint32Value;
@property (nonatomic,assign) uint64_t   uint64Value;
@property (nonatomic,copy)   NSString*  stringValue;
@property (nonatomic,retain) NSArray *  arrayValue;

@end

@implementation PKTestObject

@synthesize observedValues;
@synthesize boolValue, floatValue, doubleValue, integerValue, uintegerValue;
@synthesize int8Value, int16Value, int32Value, int64Value;
@synthesize uint8Value, uint16Value, uint32Value, uint64Value;
@synthesize stringValue, arrayValue = _arrayValue;

+ (void)initialize
{
    [self addObservedProperty:@"boolValue"];
    [self addObservedProperty:@"floatValue"];
    [self addObservedProperty:@"doubleValue"];
    [self addObservedProperty:@"integerValue"];
    [self addObservedProperty:@"uintegerValue"];
    [self addObservedProperty:@"int8Value"];
    [self addObservedProperty:@"int16Value"];
    [self addObservedProperty:@"int32Value"];
    [self addObservedProperty:@"int64Value"];
    [self addObservedProperty:@"uint8Value"];
    [self addObservedProperty:@"uint16Value"];
    [self addObservedProperty:@"uint32Value"];
    [self addObservedProperty:@"uint64Value"];
    [self addObservedProperty:@"stringValue"];
    [self addObservedProperty:@"arrayValue"];
}

- (id)init
{
    if ((self = [super init]))
    {
        self.observedValues = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)dealloc
{
    self.observedValues = nil;
    self.stringValue = nil;
    self.arrayValue = nil;
    [super dealloc];
}

- (void)observeValueForProperty:(NSString *)name value:(id)value
{
    [self.observedValues setObject:value forKey:name];
}

@end

#pragma mark - Unit Tests

@implementation PropertyKitTests

- (void)testInvalid
{
    STAssertThrows([PKProperty propertyWithName:@"bogus" forClass:[PKTestObject class]], nil);
    STAssertThrows([PKProperty propertyWithName:@"boolValue" forClass:nil], nil);
}

- (void)testEquality
{
    PKProperty *a = [PKProperty propertyWithName:@"boolValue" forClass:[PKTestObject class]];
    PKProperty *b = [PKProperty propertyWithName:@"boolValue" forClass:[PKTestObject class]];
    PKProperty *c = [PKProperty propertyWithName:@"floatValue" forClass:[PKTestObject class]];
    STAssertEqualObjects(a, b, nil);
    STAssertFalse([a isEqual:c], nil);
}

- (void)testAttributes
{
    PKProperty *a = [PKProperty propertyWithName:@"boolValue" forClass:[PKTestObject class]];
    STAssertFalse(a.isNonAtomic, nil);
    STAssertEquals(a.setterSemantics, PKPropertySetterSemanticsAssign, nil);
    STAssertEqualObjects(a.ivarName, @"boolValue", nil);
    STAssertNil((id)a.customGetter, nil);
    STAssertNil((id)a.customSetter, nil);

    PKProperty *b = [PKProperty propertyWithName:@"stringValue" forClass:[PKTestObject class]];
    STAssertTrue(b.isNonAtomic, nil);
    STAssertEquals(b.setterSemantics, PKPropertySetterSemanticsCopy, nil);
    STAssertEqualObjects(b.ivarName, @"stringValue", nil);
    STAssertNil((id)b.customGetter, nil);
    STAssertNil((id)b.customSetter, nil);

    PKProperty *c = [PKProperty propertyWithName:@"arrayValue" forClass:[PKTestObject class]];
    STAssertTrue(c.isNonAtomic, nil);
    STAssertEquals(c.setterSemantics, PKPropertySetterSemanticsRetain, nil);
    STAssertEqualObjects(c.ivarName, @"_arrayValue", nil);
    STAssertNil((id)c.customGetter, nil);
    STAssertNil((id)c.customSetter, nil);
}

- (void)testObserving
{
    PKTestObject *object = [[PKTestObject alloc] init];

    const BOOL kBoolValue = YES;
    const float kFloatValue = M_PI;
    const double kDoubleValue = M_PI;
    const NSInteger kIntererValue = 5;
    NSString * kStringValue = @"String";
    NSArray * kArrayValue = [NSArray arrayWithObject:kStringValue];

    object.boolValue = kBoolValue;
    object.floatValue = kFloatValue;
    object.doubleValue = kDoubleValue;
    object.integerValue = kIntererValue;
    object.stringValue = kStringValue;
    object.arrayValue = kArrayValue;

    STAssertEquals(object.boolValue, kBoolValue, nil);
    STAssertEquals(object.floatValue, kFloatValue, nil);
    STAssertEquals(object.doubleValue, kDoubleValue, nil);
    STAssertEquals(object.integerValue, kIntererValue, nil);
    STAssertEqualObjects(object.stringValue, kStringValue, nil);
    STAssertEqualObjects(object.arrayValue, kArrayValue, nil);

    NSDictionary *d = object.observedValues;
    STAssertEquals([[d objectForKey:@"boolValue"] boolValue], kBoolValue, nil);
    STAssertEquals([[d objectForKey:@"floatValue"] floatValue], kFloatValue, nil);
    STAssertEquals([[d objectForKey:@"doubleValue"] doubleValue], kDoubleValue, nil);
    STAssertEquals([[d objectForKey:@"integerValue"] integerValue], (NSInteger)5, nil);
    STAssertEqualObjects([d objectForKey:@"stringValue"], kStringValue, nil);
    STAssertEqualObjects([d objectForKey:@"arrayValue"], kArrayValue, nil);

    [object release];
}
@end
