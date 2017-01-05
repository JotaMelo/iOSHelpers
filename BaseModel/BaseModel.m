//
//  BaseModel.m
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "BaseModel.h"
#import "NSObject+Properties.h"

static NSString * const BaseModelDefaultDateFormat = @"yyyy/MM/dd HH:mm:ss";

@interface BaseModel ()

@property (strong, nonatomic) NSMutableDictionary *keyMap;

@end

@implementation BaseModel

+ (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    return [[self alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if ([dictionary isKindOfClass:[NSDictionary class]]) {
        self = [super init];
        if (self) {
            self.originalDictionary = dictionary;
        }
        return self;
    } else {
        return nil;
    }
}

#pragma mark - Accessors / Setters

- (NSString *)modelDateFormat
{
    if (!_modelDateFormat) {
        return BaseModelDefaultDateFormat;
    }
    
    return _modelDateFormat;
}

- (void)setOriginalDictionary:(NSDictionary *)dictionary
{
    _originalDictionary = dictionary;
    
    self.keyMap = @{}.mutableCopy;
    
    for (NSString *key in dictionary.allKeys) {
        // make it pretty
        NSString *fixedKey = [self fixKey:key];
        
        self.keyMap[fixedKey] = @{@"key": key};
        
        if ([self hasPropertyNamed:fixedKey] && ![fixedKey isEqualToString:@"description"]) {
            if (dictionary[key] != [NSNull null]) {
                NSArray<Class> *classes = [self classesOfPropertyNamed:fixedKey];
                
                self.keyMap[fixedKey] = @{@"key": key, @"class": [dictionary[key] class]};
                
                if (classes.count == 1) {
                    Class class = classes.firstObject;
                    
                    // if the class is one of my beloved childs, let's just do the magic here
                    Class superclass = class_getSuperclass(class);
                    if ([self isClass:superclass equalToClass:[BaseModel class]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        id modelItem = [class performSelector:NSSelectorFromString(@"initWithDictionary:") withObject:dictionary[key]];
#pragma clang diagnotic pop
                        
                        [self setValue:modelItem forKey:fixedKey];
                    } else if (class == [NSDate class]) {
                        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                        formatter.dateFormat = self.modelDateFormat;
                        
                        [self setValue:[formatter dateFromString:dictionary[key]] forKey:fixedKey];
                    } else if (class == [NSURL class]) {
                        if ([dictionary[key] isKindOfClass:[NSString class]]) {
                            [self setValue:[NSURL URLWithString:dictionary[key]] forKey:fixedKey];
                        }
                    } else if (class == [NSNumber class] && [dictionary[key] isKindOfClass:[NSString class]]) {
                        // if the property is NSNumber and the object in the dict is an NSString
                        // we convert that string to a number. Why would this happen? Well, some
                        // stupid API dev might have sent what should be a number as a string (????)
                        // so it's easier to just declare the property as a number and let us
                        // do all the dirty work.
                        [self setValue:@([dictionary[key] floatValue]) forKey:fixedKey];
                    } else {
                        [self setValue:dictionary[key] forKey:fixedKey];
                    }
                } else if (classes.count == 2) {
                    Class mainClass = classes.firstObject;
                    Class subClass = classes.lastObject;
                    
                    // if it isn't an array nothing makes sense
                    if (mainClass == [NSArray class]) {
                        NSMutableArray *modelArray = @[].mutableCopy;
                        
                        // looping through the array in the dictionary
                        for (NSDictionary *model in dictionary[key]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                            id modelItem = [subClass performSelector:NSSelectorFromString(@"initWithDictionary:") withObject:model];
#pragma clang diagnotic pop
                            
                            [modelArray addObject:modelItem];
                        }
                        
                        [self setValue:modelArray forKey:fixedKey];
                    }
                }
            }
        }
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *modelDictionary = @{}.mutableCopy;
    
    for (NSString *fixedKey in self.keyMap.allKeys) {
        NSDictionary *keyInfo = self.keyMap[fixedKey];
        
        NSString *key = keyInfo[@"key"];
        Class originalClass = keyInfo[@"class"];
        
        id value = [self valueForKey:fixedKey];
        
        if (value) {
            if ([value isKindOfClass:[BaseModel class]]) {
                BaseModel *baseModelObject = value;
                modelDictionary[key] = baseModelObject.dictionaryRepresentation;
            } else if ([value isKindOfClass:[NSArray class]] && [value count] > 0 && [value[0] isKindOfClass:[BaseModel class]]) {
                NSArray<BaseModel *> *baseModelArray = value;
                NSMutableArray *dictionaryArray = @[].mutableCopy;
                
                for (BaseModel *baseModelObject in baseModelArray) {
                    [dictionaryArray addObject:baseModelObject.dictionaryRepresentation];
                }
                
                modelDictionary[key] = dictionaryArray;
            } else if ([value isKindOfClass:[NSDate class]]) {
                NSDateFormatter *dateFormatter = [NSDateFormatter new];
                dateFormatter.dateFormat = self.modelDateFormat;
                
                modelDictionary[key] = [dateFormatter stringFromDate:value];
            } else {
                if ([value isKindOfClass:originalClass]) {
                    modelDictionary[key] = value;
                } else {
                    // there's just this option in this case (check line 67)
                    if ([value isKindOfClass:[NSNumber class]] && [[originalClass new] isKindOfClass:[NSString class]]) {
                        modelDictionary[key] = [value stringValue];
                    }
                }
            }
        } else {
            modelDictionary[key] = [NSNull null];
        }
    }
    
    return modelDictionary;
}

#pragma mark - Helpers

- (NSString *)fixKey:(NSString *)key
{
    NSMutableString *fixedKey = @"".mutableCopy;
    
    // converting underscore_separated_variables to a prettier camelCase
    NSArray *components = [key componentsSeparatedByString:@"_"];
    BOOL first = YES;
    for (NSString *component in components) {
        [fixedKey appendString:first ? component : component.capitalizedString];
        first = NO;
    }
    
    if ([key isEqualToString:@"id"] || [key isEqualToString:@"_id"]) {
        fixedKey = @"uid".mutableCopy;
    }
    
    // "pizza_id" becomes "pizzaID" and not "pizzaId" because oh god that's ugly
    if ([fixedKey hasSuffix:@"Id"] && [key hasSuffix:@"_id"]) {
        fixedKey = [fixedKey stringByReplacingOccurrencesOfString:@"Id" withString:@"ID"].mutableCopy;
    }
    
    // lastly, we convert the first character to lowercase to avoid WindowsStyleNaming from Windows based APIs (urgh)
    NSString *fixedFirstCharacter = [fixedKey substringToIndex:1].lowercaseString;
    [fixedKey replaceCharactersInRange:NSMakeRange(0, 1) withString:fixedFirstCharacter];
    
    return fixedKey;
}

// Previously class comparison was done using ==, but one day a unit test failed.
// Turns out the runtime funciotns (class_getSuperclass, NSStringFromClass etc) were
// returning different pointers than [ClassName class], so best way was to get their
// names and used that to compare.
//
// ref http://stackoverflow.com/a/16426371/1757960
- (BOOL)isClass:(Class)class1 equalToClass:(Class)class2
{
    const char *class1Name = class_getName(class1);
    const char *class2Name = class_getName(class2);
    
    return strcmp(class1Name, class2Name) == 0;
}

// an array can conform to a protocol with the same name as BaseModel subclass
// like this:
//
// @protocol MyModel
// @end
// @property (strong, nonatomic) NSArray<MyModel> *myArrayOfMyModels;
//
// when that's the case we find the name of the protocol, and use that
// to create an array of BaseModels automagically. So we'll have two classes
// in the resulting array of this method
// 1 - NSArray (duh)
// 2 - BaseModel subclass
//
// If the property doesn't conform to a protocol, or it conforms to a protocol
// that isn't a BaseModel subclass, there will be only 1 class in the array
- (NSArray<Class> *)classesOfPropertyNamed:(NSString *)property
{
    NSString *originalClassName = [NSString stringWithUTF8String:[self typeOfPropertyNamed:property]];
    
    // from my testing, the "originalClassName" for primitive types is 2 characters and starts with an uppercase T
    // if it's a primitive, let it be handled as an NSNumber
    // (I have no clue what "T^B" is, it was here before and I didn't want to remove it)
    if ([originalClassName isEqualToString:@"T^B"] || (originalClassName.length == 2 && [originalClassName hasPrefix:@"T"])) {
        return @[[NSNumber class]];
    } else if (originalClassName.length > 3) {
        NSString *className = [[originalClassName stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        Class protocolClass;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\<.*\\>" options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:className options:0 range:NSMakeRange(0, className.length)];
        
        if (matches.count > 0) {
            // with < and >
            NSString *originalProtocolString = [className substringWithRange:matches.firstObject.range];
            
            // no < and >
            NSString *strippedProtocolString = [originalProtocolString substringWithRange:NSMakeRange(1, originalProtocolString.length - 2)];
            
            // multiple protocols come in this format:
            // NSArray<Protocol1><Protocol2>
            // the regex matches <Protocol1><Protocol2>
            // so we'll do a split on >< to loop through
            // multiple protocols
            for (NSString *protocol in [strippedProtocolString componentsSeparatedByString:@"><"]) {
                NSString *strippedSingleProtocolName = [protocol stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                Class class = NSClassFromString(strippedSingleProtocolName);
                if (class && [self isClass:class_getSuperclass(class) equalToClass:[BaseModel class]]) {
                    protocolClass = class;
                    break;
                }
            }
            
            className = [className stringByReplacingOccurrencesOfString:originalProtocolString withString:@""];
            
            if (protocolClass) {
                return @[NSClassFromString(className), protocolClass];
            } else {
                return @[NSClassFromString(className)];
            }
        } else
            return @[NSClassFromString(className)];
    }
    
    return nil;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    BaseModel *copy = [[self class] allocWithZone:zone];
    
    NSArray *properties = [self propertyNames];
    for (NSString *propertyName in properties) {
        if (propertyName) {
            if ([self setterForPropertyNamed:propertyName]) {
                id value = [self valueForKey:propertyName];
                
                if ([value conformsToProtocol:@protocol(NSCopying)]) {
                    [copy setValue:[value copy] forKey:propertyName];
                } else {
                    [copy setValue:value forKey:propertyName];
                }
            }
        }
    }
    
    return copy;
}

#pragma mark -

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        BaseModel *model = object;
        
        if (!model.uid || !self.uid) {
            return NO;
        }
        
        return [model.uid isEqualToNumber:self.uid];
    } else {
        return NO;
    }
}

@end
