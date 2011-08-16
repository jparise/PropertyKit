# PropertyKit for Objective-C

PropertyKit provides tools for working with [Objective-C Declared
Properties][properties].

Copyright &copy; 2011, Jon Parise.

## Installation

Simply include these source files in your project:

* PropertyKit.h
* PropertyKit.mm

The repository also includes a SenTestingKit-compatible unit test:

* PropertyKitTests.h
* PropertyKitTests.m

## Usage

### Introspection

Objective-C properties have a name and a set of attributes.  The Objective-C
runtime represents these attributes as a [property type string][typestring].
Accessing individual attributes involves parsing this custom string format.
PropertyKit handles this parsing for you and provides two convenient ways to
access property attributes.

The C API wraps the low-level parser:

```objective-c
objc_property_t property = class_getProperty([UIView class], "hidden");
PKPropertyAttributes attributes = PKPropertyAttributesMake(property);
NSLog(@"Property %s uses ivar %s", property_getName(property), attributes.ivarName);
```

And the higher-level `PKProperty` class provides more convenient access:

```objective-c
PKProperty *property = [PKProperty propertyWithName:@"hidden" forClass:[UIView class]];
NSLog(@"Property %@ uses ivar %@", property.name, property.ivarName);
```

### Observing

PropertyKit provides a mechanism for observing changes to property values.
This is similar to [Key-Value Observing][kvo] but trades features for speed.
It works by replacing synthesized property setters with custom implementations
that call an object-level notification selector when a property is changed.

Objects can only observe their own properties; objects cannot directly observe
the properties of other objects.

Observed properties need to be registered:

```objective-c
+ (void)initialize
{
    [self addObservedProperty:@"hidden"];
}
```

The object will then be notified of changes to observed properties:

```objective-c
- (void)observeValueForProperty:(NSString *)name value:(id)value
{
    NSLog(@"Property %@ has a new value: %@", name, value);
}
```

## Future Ideas

### Observing

* Consider sending both the old and new values to the observer.
* Support structs (e.g. `CGRect`). This will require wrapping the new value in
  an [`NSValue`][nsvalue] box so that it could be passed back to the observer.
* Support atomic (synchronized) setter operations.
* Emit [KVO][kvo] notifications from our custom setter implementations.
* Offer the option of using [method swizzling][swizzling] to call the original
  setter instead of completely replacing the setter implementation. This will
  provide greater end-user flexibility at the expense of some speed.

[properties]: http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/ObjectiveC/Chapters/ocProperties.html
[typestring]: https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
[kvo]: http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html
[nsvalue]: http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSValue_Class/Reference/Reference.html
[swizzling]: http://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html
