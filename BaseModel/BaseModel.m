//
//  BaseModel.m
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "BaseModel.h"
#import "NSObject+Properties.h"

@implementation BaseModel

+ (instancetype)initWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    if ([dict isKindOfClass:[NSDictionary class]]) {
        self = [super init];
        if (self) {
            self.originalDict = dict;
            
            for (NSString *key in dict.allKeys) {
                NSMutableString *fixedKey = @"".mutableCopy;
                
                NSArray *components = [key componentsSeparatedByString:@"_"];
                BOOL first = YES;
                for (NSString *component in components) {
                    [fixedKey appendString:first ? component : component.capitalizedString];
                    first = NO;
                }
                
                if ([key isEqualToString:@"id"] || [key isEqualToString:@"_id"]) fixedKey = @"uid".mutableCopy;
                
                if ([self hasPropertyNamed:fixedKey]) {
                    if (dict[key] != [NSNull null]) {
                        Class class = [self classOfPropertyNamed:fixedKey];
                        
                        if (class == [NSDate class]) {
                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                            formatter.dateFormat = @"yyyyMMddHH:mm:ss"; //insira aqui o formato de data usado na API
                            
                            [self setValue:[formatter dateFromString:dict[key]] forKey:fixedKey];
                        } else
                            [self setValue:dict[key] forKey:fixedKey];
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
    if ([originalClassName isEqualToString:@"T^B"])
        return [NSNumber class];
    else {
        NSString *className = [[originalClassName stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@""] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        return NSClassFromString(className);
    }
}

- (NSString *)json
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.originalDict options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
