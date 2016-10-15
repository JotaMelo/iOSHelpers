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

+ (NSArray *)transformDictionaryArray:(NSArray<NSDictionary *> *)array intoArrayOfModels:(Class)class
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

+ (UIImage *)fixOrientationForImage:(UIImage *)image
{
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, .0f);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, .0f);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, .0f);
            transform = CGAffineTransformScale(transform, -1.f, 1.f);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(.0f, .0f, image.size.height, image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (UIImage *)blurImage:(UIImage *)image
{
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
    
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [gaussianBlurFilter setValue:inputImage forKey:@"inputImage"];
    [gaussianBlurFilter setValue:@12.9 forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:gaussianBlurFilter.outputImage fromRect:inputImage.extent];
    
    UIGraphicsBeginImageContext(inputImage.extent.size);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    CGContextScaleCTM(outputContext, 1.f, -1.f);
    CGContextTranslateCTM(outputContext, .0f, -inputImage.extent.size.height);
    
    CGContextDrawImage(outputContext, inputImage.extent, cgImage);
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
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
