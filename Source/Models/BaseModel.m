//
//  MPIBaseModel.m
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import "BaseModel.h"
#import "PropertyUtil.h"

#define mustOverride() @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%s must be overridden in a subclass/category", __PRETTY_FUNCTION__] userInfo:nil]

@interface MPIBaseModel ()
@property (readonly) NSDictionary* sourceDictionary;
@end

@implementation MPIBaseModel


- (instancetype) init {
    return [self initWithDictionary: nil];
}

- (instancetype) initWithDictionary: (NSDictionary*)dictionary {
    self = [super init];
    if (self) {
        if (dictionary) {
            _sourceDictionary = dictionary;
            // get property name to type mapping
            NSDictionary* classProperties = [MPIPropertyUtil classPropsFor:[self class]];
            for (NSString* propName in classProperties) {
                // attempt to get value from dictionary
                // TODO: support casting to different types
                NSString* value = dictionary[propName];
                if (value) {
                    [self setValue:value forKey:propName];
                }
            }
            
            // don't return new object if the dictionary didn't pass validity
            if ([self isValid] == NO) {
                NSLog(@"MPIBaseModel didn't generate model. Invalid properties in dictionary.");
                self = nil;
            }
        }
    }
    return self;
}

- (NSDictionary*) convertToDictionary {
    
    NSMutableDictionary *valueDictionary = [NSMutableDictionary dictionary];
    
    // get property name to type mapping
    NSDictionary* classProperties = [MPIPropertyUtil classPropsFor:[self class]];
    for (NSString* propName in classProperties) {
        // attempt to get value from self
        SEL propertySelector = NSSelectorFromString(propName);
        if ([self respondsToSelector:propertySelector]) {
            @try {
                [valueDictionary setValue:[self performSelector:propertySelector] forKey:propName];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception while trying to convert object to dictionary: %@", exception.description);
            }
        }
    }
    return valueDictionary;
}

- (BOOL) isValid {
    mustOverride();
}

@end
