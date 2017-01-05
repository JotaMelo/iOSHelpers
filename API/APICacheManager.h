//
//  APICacheManager.h
//  v1.0
//
//  Created by Jota Melo on 21/12/16.
//  Copyright © 2016 iOasys. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "API.h"

@interface APICacheManager : NSObject

@property (class, readonly, nonatomic) APICacheManager *sharedManager;
@property (assign, nonatomic) NSUInteger inMemoryCacheMaxSize; // bytes

- (NSString *)cacheFileNameWithPath:(NSString *)path method:(NSString *)method parameters:(NSDictionary *)parameters;

- (BOOL)callBlock:(APIResponseBlock)block ifCacheExistsForFileName:(NSString *)cacheFileName;

- (void)writeData:(id)data toCacheFile:(NSString *)cacheFileName;

- (void)clearCache;

@end
