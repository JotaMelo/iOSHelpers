//
//  Helper.m
//  Dona Redonda
//
//  Created by Jota Melo on 1/4/16.
//  Copyright © 2016 iOasys. All rights reserved.
//

#import "Helper.h"

@interface Helper ()

@end

@implementation Helper

+ (instancetype)sharedHelper
{
    static Helper *sharedHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHelper = [self new];
    });
    return sharedHelper;
}

+ (NSArray *)array:(NSArray *)array ofClass:(__unsafe_unretained Class)class
{
    NSMutableArray *newArray = [NSMutableArray new];
    
    for (NSDictionary *item in array) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id parsedItem = [class performSelector:NSSelectorFromString(@"initWithDictionary:") withObject:item];
#pragma clang diagnostic pop
        [newArray addObject:parsedItem];
    }
    
    return newArray;
}

#if TARGET_OS_IOS
+ (UIBarButtonItem *)barButtonWithImage:(UIImage *)img target:(id)target andAction:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setUserInteractionEnabled:YES];
    [button setBackgroundImage:img forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 6, img.size.width, img.size.height)];
    
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}
#endif

+ (BOOL)validateEmailWithString:(NSString *)checkString
{
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

#pragma mark - Defaults

+ (NSUserDefaults *)userDefaults
{
    return [NSUserDefaults standardUserDefaults];
    // or if you use app groups:
    //return [[NSUserDefaults alloc] initWithSuiteName:@"group.jota.etc"];
}

+ (id)defaultsObjectForKey:(NSString *)key
{
    return [self.userDefaults objectForKey:key];
}

+ (void)setDefaultsObject:(id)object forKey:(NSString *)key
{
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setObject:object forKey:key];
    [defaults synchronize];
}

+ (void)removeDefaultsObjectForKey:(NSString *)key
{
    NSUserDefaults *defaults = self.userDefaults;
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

+ (void)clearUserDefaults
{
    for (NSString *key in self.userDefaults.dictionaryRepresentation.allKeys)
        [self removeDefaultsObjectForKey:key];
}

@end
