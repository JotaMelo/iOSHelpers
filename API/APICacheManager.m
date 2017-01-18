//
//  APICacheManager.m
//  v1.0
//
//  Created by Jota Melo on 21/12/16.
//  Copyright © 2016 iOasys. All rights reserved.
//

#import "APICacheManager.h"

#include <CommonCrypto/CommonDigest.h>

static NSString * const kCacheFileExtension = @"apicache";
static NSUInteger const kInMemoryCacheDefaultMaxSize = 1000000; // in bytes, 1MB

@interface APIMemoryCacheItem : NSObject

@property (strong, nonatomic) NSString *key;
@property (strong, nonatomic) id data;
@property (assign, nonatomic) NSUInteger size;
@property (assign, nonatomic) NSUInteger accessCount;

@end

@implementation APIMemoryCacheItem

+ (instancetype)memoryCacheItemWithKey:(NSString *)key data:(id)data
{
    APIMemoryCacheItem *item = [APIMemoryCacheItem new];
    item.key = key;
    item.data = data;
    return item;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<APIMemoryCacheItem: %p> size: %ld accessCount: %ld", self, (unsigned long)self.size, (unsigned long)self.accessCount];
}

@end


@interface APICacheManager ()

@property (nonatomic, readonly) NSArray<NSURL *> *cacheFiles;
@property (strong, nonatomic) NSMutableDictionary<NSString *, APIMemoryCacheItem *> *memoryCache;
@property (assign, nonatomic) NSUInteger currentSize;

@end

@implementation APICacheManager

+ (APICacheManager *)sharedManager
{
    static APICacheManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [APICacheManager new];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.memoryCache = @{}.mutableCopy;
        self.inMemoryCacheMaxSize = kInMemoryCacheDefaultMaxSize;
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            [self loadMemoryCache];
        });
    }
    return self;
}

- (NSArray<NSURL *> *)cacheFiles
{
    NSURL *documentsDirectory = [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
    NSFileManager *localFileManager = [NSFileManager new];
    NSDirectoryEnumerator *directoryEnumerator = [localFileManager enumeratorAtURL:documentsDirectory includingPropertiesForKeys:nil options:0 errorHandler:nil];
    
    NSMutableArray<NSURL *> *files = @[].mutableCopy;
    for (NSURL *fileURL in directoryEnumerator) {
        if ([fileURL.pathExtension isEqualToString:kCacheFileExtension]) {
            [files addObject:fileURL];
        }
    }
    
    return files;
}

#pragma mark -

- (void)loadMemoryCache
{
    for (NSURL *fileURL in self.cacheFiles) {
        APIMemoryCacheItem *item = [self cacheItemForURL:fileURL];
        if (self.currentSize + item.size <= self.inMemoryCacheMaxSize) {
            self.memoryCache[item.key] = item;
            self.currentSize += item.size;
        } else {
            break;
        }
    }
}

- (NSString *)cacheFileNameWithPath:(NSString *)path method:(NSString *)method parameters:(NSDictionary *)parameters
{
    NSMutableData *encodedData = [NSMutableData new];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:encodedData];
    [archiver encodeObject:path forKey:@"path"];
    [archiver encodeObject:method forKey:@"method"];
    [archiver encodeObject:parameters forKey:@"parameters"];
    [archiver finishEncoding];
    
    NSString *fileName = [self calculateSHA1ForData:encodedData];
    
    return [NSString stringWithFormat:@"%@.%@", fileName, kCacheFileExtension];
}

- (void)writeData:(id)data toCacheFile:(NSString *)cacheFileName
{
    if (data && cacheFileName) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            if (self.memoryCache[cacheFileName]) {
                self.memoryCache[cacheFileName].data = data;
                self.currentSize -= self.memoryCache[cacheFileName].size; // new size will be added at the end
            } else {
                self.memoryCache[cacheFileName] = [APIMemoryCacheItem memoryCacheItemWithKey:cacheFileName data:data];
            }
            
            NSURL *cacheURL = [self URLForFileName:cacheFileName];
            NSMutableData *fileData = [NSMutableData new];
            
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:fileData];
            [archiver encodeObject:@{@"data": data} forKey:@"data"];
            [archiver finishEncoding];
            
            [fileData writeToURL:cacheURL atomically:YES];
            
            self.memoryCache[cacheFileName].size = fileData.length;
            self.currentSize += fileData.length;
            
            if (self.currentSize > self.inMemoryCacheMaxSize) {
                [self optimizeInMemoryCache];
            }
        });
    }
}

- (BOOL)callBlock:(APIResponseBlock)block ifCacheExistsForFileName:(NSString *)cacheFileName
{
    if (self.memoryCache[cacheFileName]) {
        APIMemoryCacheItem *item = self.memoryCache[cacheFileName];
        item.accessCount++;
        
        [self callResponseBlock:block onMainThreadWithData:item.data error:nil cache:YES];
        
        return YES;
    }
    
    NSFileManager *localFileManager = [NSFileManager new];
    NSURL *cacheURL = [self URLForFileName:cacheFileName];
    
    if ([localFileManager fileExistsAtPath:cacheURL.path]) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            APIMemoryCacheItem *item = [self cacheItemForURL:cacheURL];
            [self callResponseBlock:block onMainThreadWithData:item.data error:nil cache:YES];
        });
        
        return YES;
    }
    
    return NO;
}

- (void)clearCache
{
    self.memoryCache = @{}.mutableCopy;

    NSFileManager *localFileManager = [NSFileManager new];
    for (NSURL *file in self.cacheFiles) {
        [localFileManager removeItemAtURL:file error:nil];
    }
}

#pragma mark - Helpers

- (NSURL *)URLForFileName:(NSString *)fileName
{
    NSURL *documentsDirectory = [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].lastObject;
    NSURL *fileURL = [documentsDirectory URLByAppendingPathComponent:fileName];
    return fileURL;
}

- (NSString *)calculateSHA1ForData:(NSData *)data
{
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    if (CC_SHA1(data.bytes, (CC_LONG)data.length, digest)) {
        NSMutableString *hexString = [NSMutableString string];
        for (int i = 0; i < 20; i++) {
            [hexString appendFormat:@"%02x", digest[i]];
        }
        
        return hexString;
    }
    
    return nil;
}

- (APIMemoryCacheItem *)cacheItemForURL:(NSURL *)URL
{
    NSData *data = [[NSMutableData alloc] initWithContentsOfURL:URL];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSMutableDictionary *response = [[NSMutableDictionary alloc] initWithDictionary:[unarchiver decodeObjectForKey:@"data"]];
    
    APIMemoryCacheItem *item = [APIMemoryCacheItem memoryCacheItemWithKey:URL.lastPathComponent data:response[@"data"]];
    item.size = data.length;
    
    return item;
}

- (void)callResponseBlock:(APIResponseBlock)block onMainThreadWithData:(id)data error:(NSError *)error cache:(BOOL)cache
{
    if (block) {
        if (NSThread.isMainThread) {
            block(data, error, cache);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(data, error, cache);
            });
        }
    }
}

// Favors most accessed items
- (void)optimizeInMemoryCache
{
    NSArray<APIMemoryCacheItem *> *sortedItems = [self.memoryCache.allValues sortedArrayUsingComparator:^NSComparisonResult(APIMemoryCacheItem * _Nonnull obj1, APIMemoryCacheItem * _Nonnull obj2) {
        return [@(obj1.accessCount) compare:@(obj2.accessCount)];
    }].reverseObjectEnumerator.allObjects;
    
    self.memoryCache = @{}.mutableCopy;
    self.currentSize = 0;
    
    for (APIMemoryCacheItem *item in sortedItems) {
        if (self.currentSize + item.size <= self.inMemoryCacheMaxSize) {
            self.memoryCache[item.key] = item;
            self.currentSize += item.size;
        } else {
            break;
        }
    }
}


@end
