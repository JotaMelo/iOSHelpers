//
//  BaseModel.m
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "BaseModel.h"
#import "NSObject+Properties.h"

#define DATE_FORMAT @"yyyy-MM-dd'T'HH:mm:ssZZZZ"

@implementation BaseModel

+ (instancetype)initWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        self = [super init];
        if (self) {
            self.originalDict = dict;
            
            for (NSString *key in dict.allKeys) {
                NSMutableString *fixedKey = @"".mutableCopy;
                
                // converting underscore_separated_variables to a prettier camelCase
                NSArray *components = [key componentsSeparatedByString:@"_"];
                BOOL first = YES;
                for (NSString *component in components) {
                    [fixedKey appendString:first ? component : component.capitalizedString];
                    first = NO;
                }
                
                if ([key isEqualToString:@"id"] || [key isEqualToString:@"_id"]) fixedKey = @"uid".mutableCopy;
                
                // "pizza_id" becomes "pizzaID" and not "pizzaId" because oh god that's ugly
                if ([fixedKey hasSuffix:@"Id"] && [key hasSuffix:@"_id"])
                    fixedKey = [fixedKey stringByReplacingOccurrencesOfString:@"Id" withString:@"ID"].mutableCopy;
                
                if ([self hasPropertyNamed:fixedKey] && ![fixedKey isEqualToString:@"description"]) {
                    if (dict[key] != [NSNull null]) {
                        Class class = [self classOfPropertyNamed:fixedKey];
                        
                        if (class) {
                            // if the class is one of my beloved childs, let's just do the magic here
                            if (class_getSuperclass(class) == [BaseModel class]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                                id modelItem = [class performSelector:NSSelectorFromString(@"initWithDictionary:") withObject:dict[key]];
#pragma clang diagnotic pop
                                
                                [self setValue:modelItem forKey:fixedKey];
                            } else if (class == [NSDate class]) {
                                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                formatter.dateFormat = DATE_FORMAT;
                                
                                [self setValue:[formatter dateFromString:dict[key]] forKey:fixedKey];
                            } else if (class == [NSURL class]) {
                                if ([dict[key] isKindOfClass:[NSString class]])
                                    [self setValue:[NSURL URLWithString:dict[key]] forKey:fixedKey];
                            } else if (class == [NSNumber class] && [dict[key] isKindOfClass:[NSString class]]) {
                                // if the property is NSNumber and the object in the dict is an NSString
                                // we convert that string to a number. Why would this happen? Well, some
                                // stupid API dev might have sent what should be a number as a string (????)
                                // so it's easier to just declare the property as a number and let this
                                // class do all the dirty work
                                [self setValue:@([dict[key] floatValue]) forKey:fixedKey];
                            } else
                                [self setValue:dict[key] forKey:fixedKey];
                        }
                    }
                }
            }
        }
        return self;
    } else
        return nil;
}

- (__unsafe_unretained Class)classOfPropertyNamed:(NSString *)property
{
    NSString *originalClassName = [NSString stringWithUTF8String:[self typeOfPropertyNamed:property]];
    
    // from my testing, the "originalClassName" for primitive types is 2 characters and starts with an uppercase T
    // if it's a primitive, let it be handled as an NSNumber
    // (I have no clue what "T^B" is, it was here before and I didn't want to remove it)
    if ([originalClassName isEqualToString:@"T^B"] || (originalClassName.length == 2 && [originalClassName hasPrefix:@"T"]))
        return [NSNumber class];
    else if (originalClassName.length > 3) {
        NSString *className = [[originalClassName stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        return NSClassFromString(className);
    }
    
    return nil;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        BaseModel *model = object;
        
        if (!model.uid || !self.uid)
            return NO;
        
        return [model.uid isEqualToNumber:self.uid];
    } else
        return NO;
}

@end
