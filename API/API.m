//
//  API.m
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "API.h"
#import "AFNetworking.h"


@implementation API

NSString *const kBaseURL = @"http://example.com/api/";

NSString *const GET     = @"GET";
NSString *const POST    = @"POST";
NSString *const PUT     = @"PUT";
NSString *const PATCH   = @"PATCH";
NSString *const DELETE  = @"DELETE";


#pragma mark - API methods

// API methods go here

#pragma mark - Cache

+ (NSString *)cacheFileNameWithPath:(NSString *)path
                             method:(NSString *)method
                             params:(NSDictionary *)params
{
    NSMutableString *fileName = [NSString stringWithFormat:@"%@_%@", method, path].mutableCopy;
    
    for (NSString *key in params.allKeys)
        [fileName appendFormat:@"_%@", params[key]];
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"-"].mutableCopy;
    
    return fileName;
}

+ (BOOL)returnCacheIfExistsForFileName:(NSString *)cacheFileName
                            completion:(RequestBlock)block
{
    NSURL *cacheURL = [self URLForFileName:cacheFileName];
    
    if ([NSFileManager.defaultManager fileExistsAtPath:cacheURL.path]) {
        NSData *data = [[NSMutableData alloc] initWithContentsOfURL:cacheURL];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSMutableDictionary *response = [[NSMutableDictionary alloc] initWithDictionary:[unarchiver decodeObjectForKey:@"data"]];
        
        if (block)
            block(response[@"data"], nil, YES);
        
        return YES;
    }
    
    return NO;
}

+ (void)writeData:(id)data
      toCacheFile:(NSString *)cacheFileName
{
    if (data && cacheFileName) {
        NSURL *cacheURL = [self URLForFileName:cacheFileName];
        NSMutableData *fileData = [[NSMutableData alloc] init];
        
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:fileData];
        [archiver encodeObject:@{@"data": data} forKey:@"data"];
        [archiver finishEncoding];
        
        [fileData writeToURL:cacheURL atomically:YES];
    }
}

+ (NSURL *)URLForFileName:(NSString *)fileName
{
    NSURL *documentsDirectory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].lastObject;
    NSURL *fileURL = [documentsDirectory URLByAppendingPathComponent:fileName];
    return fileURL;
}

+ (void)clearCache
{
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *directoryEnumerator = [localFileManager enumeratorAtPath:documentsDirectory];
    
    NSString *file;
    while ((file = directoryEnumerator.nextObject)) {
        if ([file hasSuffix:@".apicache"]) {
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, file];
            [localFileManager removeItemAtPath:fullPath error:nil];
        }
    }
}

#pragma mark - Helpers

+ (NSString *)mimeTypeForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
            break;
        case 0x89:
            return @"image/png";
            break;
        case 0x47:
            return @"image/gif";
            break;
        case 0x49:
        case 0x4D:
            return @"image/tiff";
            break;
        case 0x25:
            return @"application/pdf";
            break;
        case 0xD0:
            return @"application/vnd";
            break;
        case 0x46:
            return @"text/plain";
            break;
        default:
            return @"application/octet-stream";
    }
    
    return nil;
}

#pragma mark - HTTP

/**
 Creates and runs an `NSURLSessionDataTask`
 
 @param method             The HTTP method to be used
 @param path               The path of the request
 @param baseURL            An option baseURL to be used with the path. If nil, uses the class' default baseURL
 @param params             A dictionary of parameters. If any of the values is of type NSData (or an array of NSData), the request will be sent as a multipart/form-data
 @param extraHeaders       These headers will be appended to the request
 @param suppressErrorAlert Should silence the default error alert of the method
 @param uploadBlock        A block that reports the progress of the request's upload
 @param downloadBlock      A block that reports the progress of the request's download
 @param cacheOption        The cache option to be used for this request, check the definition in the header for more info
 @param completion         A block called when the request in completed. It takes an id (the response object), NSError (the error of the request if any) and a BOOL (indicating if the request came from the cache)
 */

+ (NSURLSessionDataTask *)make:(NSString *)method
               requestWithPath:(NSString *)path
                       baseURL:(NSURL *)baseURL
                        params:(NSDictionary *)immutableParams
                  extraHeaders:(NSDictionary *)extraHeaders
            suppressErrorAlert:(BOOL)supressErrorAlert
                   uploadBlock:(void(^)(NSProgress *progress))uploadBlock
                 downloadBlock:(void(^)(NSProgress *progress))downloadBlock
                   cacheOption:(CacheOption)cacheOption
                    completion:(RequestBlock)block
{
    NSString *cacheFileName = [self cacheFileNameWithPath:path method:method params:immutableParams]; // generates the file name for cache
    BOOL hasCache = NO;
    
    if (cacheOption == CacheOptionBoth || cacheOption == CacheOptionCacheOnly) // if one of the options includes cache
        hasCache = [self returnCacheIfExistsForFileName:cacheFileName completion:block]; // this methods returns a boolean indicating if the file exists in cache and calls the block with the cached content if it exists
    
    if (cacheOption == CacheOptionBoth || cacheOption == CacheOptionNetworkOnly || !hasCache) { // if one of the options including the request or if file not in cache, let's make the request
        void(^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"\n\n%@ %@", method, task.response);
            NSLog(@"%@", responseObject);
            
            [self writeData:responseObject toCacheFile:cacheFileName]; // request ok, saves it in cache
            
            if (block)
                block(responseObject, nil, NO);
        };
        
        void(^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
#if TARGET_OS_IOS
            if (!supressErrorAlert) {
                if ([[UIApplication sharedApplication].keyWindow isMemberOfClass:[UIWindow class]]) {
                    NSString *errorMessage = error.localizedDescription;
                    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                    [[[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#pragma clang pop
                }
            }
#endif
            
            // can't get the responseObject directly in AFNetworking 3.0, so do that manually
            NSData *responseData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            id responseObject;
            
            if (responseData) {
                NSError *error;
                responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                
                if (error)
                    responseObject = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
            
            NSLog(@"\n\n%@ %@", method, task.response);
            NSLog(@"%@", responseObject);
            
            if (block)
                block(responseObject, error, NO);
        };
        
        NSMutableDictionary *params = immutableParams.mutableCopy;
        
        if (!baseURL)
            baseURL = [NSURL URLWithString:kBaseURL];
        
        AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        // add here authentication parameters/headers, if necessary
        // to add a header:
        //[manager.requestSerializer setValue:@"ccf4a12997a2c63ba278121e07a4c7fd363732ad4044bd5fc882103a9de6eeb1" forHTTPHeaderField:@"X-Auth-Token"];
        
        if (extraHeaders) {
            for (NSString *key in extraHeaders.allKeys)
                [manager.requestSerializer setValue:extraHeaders[key] forHTTPHeaderField:key];
        }
        
        NSMutableArray *dataParameters = @[].mutableCopy; // identifies parameters that are instances of NSData
        
        for (id key in params) {
            if ([params[key] isKindOfClass:[NSData class]])
                [dataParameters addObject:key];
            else if ([params[key] isKindOfClass:[NSArray class]]) {
                NSArray *array = params[key];
                if (array.count > 0 && [array.firstObject isKindOfClass:[NSData class]])
                    [dataParameters addObject:key];
            }
        }
        
        NSURLSessionDataTask *task;
        if (dataParameters.count > 0) { // requests with NSData parameters should be sent using multipart/form-data
            task = [manager dataTaskWithHTTPMethod:method URLString:path parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                for (id key in dataParameters) {
                    id param = params[key];
                    
                    if ([param isKindOfClass:[NSData class]])
                        [formData appendPartWithFileData:param name:key fileName:key mimeType:[self mimeTypeForData:param]];
                    else if ([param isKindOfClass:[NSArray class]]) {
                        NSArray *arrayOfDatas = param;
                        for (int i = 0; i < arrayOfDatas.count; i++) {
                            NSData *data = arrayOfDatas[i];
                            NSString *paramName = [NSString stringWithFormat:@"%@[%i]", key, i];
                            
                            [formData appendPartWithFileData:data name:paramName fileName:key mimeType:[self mimeTypeForData:data]];
                        }
                    }
                    
                    [params removeObjectForKey:key];
                }
                
                for (NSString *key in params) {
                    id param = params[key];
                    
                    if ([param isKindOfClass:[NSNumber class]])
                        param = [param stringValue];
                    
                    [formData appendPartWithFormData:[param dataUsingEncoding:NSUTF8StringEncoding] name:key];
                }
            } uploadProgress:uploadBlock downloadProgress:downloadBlock success:successBlock failure:failureBlock];
        } else {
            task = [manager dataTaskWithHTTPMethod:method URLString:path parameters:params constructingBodyWithBlock:nil uploadProgress:uploadBlock downloadProgress:downloadBlock success:successBlock failure:failureBlock];
        }
        
        [task resume];
        
        return task;
    }
    
    return nil;
}

// simplified method in case you don't need to use all parameters from the method above
+ (NSURLSessionDataTask *)make:(NSString *)method
               requestWithPath:(NSString *)path
                        params:(NSDictionary *)immutableParams
                   cacheOption:(CacheOption)cacheOption
                    completion:(RequestBlock)block
{
    return [self make:method requestWithPath:path baseURL:nil params:immutableParams extraHeaders:nil suppressErrorAlert:NO uploadBlock:nil downloadBlock:nil cacheOption:cacheOption completion:block];
}

@end
