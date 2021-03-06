//
//  Helper.h
//  Dona Redonda
//
//  Created by Jota Melo on 1/4/16.
//  Copyright © 2016 iOasys. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

@interface Helper : NSObject

+ (instancetype)sharedHelper;

+ (NSArray *)transformDictionaryArray:(NSArray<NSDictionary *> *)array intoArrayOfModels:(Class)class;

+ (BOOL)validateEmailWithString:(NSString *)checkString;

#if TARGET_OS_IOS
+ (UIBarButtonItem *)barButtonWithImage:(UIImage *)img target:(id)target andAction:(SEL)action;

+ (UIImage *)fixOrientationForImage:(UIImage *)image;

+ (UIImage *)blurImage:(UIImage *)image;
#endif

#pragma mark - Defaults

+ (NSUserDefaults *)userDefaults;

+ (id)defaultsObjectForKey:(NSString *)key;

+ (void)setDefaultsObject:(id)object forKey:(NSString *)key;

+ (void)removeDefaultsObjectForKey:(NSString *)key;

+ (void)clearUserDefaults;

@end
