//
//  API.m
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "API.h"
#import "AFNetworking.h"

NSString * const APIBaseURL       = @"http://baseurl";
NSString * const APIErrorDomain   = @"com.company.project.api";

NSString * const APIMethodGET     = @"GET";
NSString * const APIMethodPOST    = @"POST";
NSString * const APIMethodPUT     = @"PUT";
NSString * const APIMethodPATCH   = @"PATCH";
NSString * const APIMethodDELETE  = @"DELETE";

@interface API ()

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

@end


@implementation API

+ (AFHTTPSessionManager *)sharedSessionManager
{
    static AFHTTPSessionManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [AFHTTPSessionManager manager];
    });
    
    return sharedManager;
}

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
                            completion:(APIResponseBlock)block
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

#pragma mark - Accessors

- (NSString *)cacheFileName
{
    if (!_cacheFileName) {
        _cacheFileName = [API cacheFileNameWithPath:self.path method:self.method params:self.parameters];
    }
    
    return _cacheFileName;
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

+ (void)showErrorMessage:(NSString *)errorMessage
{
#if TARGET_OS_IOS
    if ([[UIApplication sharedApplication].keyWindow isMemberOfClass:[UIWindow class]]) {  // don't show alert on top of another alert
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#pragma clang pop
    }
#endif
}

+ (NSArray *)identifyDataParametersInParameters:(NSDictionary *)parameters
{
    NSMutableArray *dataParameters = @[].mutableCopy;
    
    for (id key in parameters) {
        if ([parameters[key] isKindOfClass:[NSData class]])
            [dataParameters addObject:key];
        else if ([parameters[key] isKindOfClass:[NSArray class]]) {
            NSArray *array = parameters[key];
            if (array.count > 0 && [array.firstObject isKindOfClass:[NSData class]])
                [dataParameters addObject:key];
        }
    }
    
    return dataParameters;
}

#pragma mark - HTTP

#pragma mark Blocks

- (APIRequestSuccessBlock)requestSuccessBlock
{
    return ^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"\n\n%@ %@", self.method, task.response);
        NSLog(@"%@", responseObject);
        
        [API writeData:responseObject toCacheFile:self.cacheFileName]; // request ok, saves it in cache
        
        if (self.completionBlock) {
            self.completionBlock(responseObject, nil, NO);
        }
    };
}

- (APIRequestFailureBlock)requestFailureBlock
{
    return ^(NSURLSessionDataTask *task, NSError *error) {
        [API showErrorMessage:error.localizedDescription];
        
        // can't get the responseObject directly in AFNetworking 3.0, so do that manually
        NSData *responseData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        id responseObject;
        
        if (responseData) {
            NSError *error;
            responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            if (error)
                responseObject = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        }
        
        NSLog(@"\n\n%@ %@", self.method, task.response);
        NSLog(@"%@", responseObject);
        
        if (self.completionBlock) {
            self.completionBlock(responseObject, error, NO);
        }
    };
}

- (APIMultipartConstructionBlock)multipartFormDataConstructionBlockWithDataParameters:(NSArray *)dataParameters
                                                                    mutableParameters:(NSMutableDictionary *)parameters
{
    return ^(id<AFMultipartFormData>  _Nonnull formData) {
        for (id key in dataParameters) {
            id parameter = parameters[key];
            
            if ([parameter isKindOfClass:[NSData class]])
                [formData appendPartWithFileData:[parameter base64EncodedDataWithOptions:0] name:key fileName:key mimeType:[API mimeTypeForData:parameter]];
            else if ([parameter isKindOfClass:[NSArray class]]) {
                NSArray *arrayOfDatas = parameter;
                for (int i = 0; i < arrayOfDatas.count; i++) {
                    NSData *data = arrayOfDatas[i];
                    NSString *paramName = [NSString stringWithFormat:@"%@[%i]", key, i];
                    
                    [formData appendPartWithFileData:data name:paramName fileName:key mimeType:[API mimeTypeForData:data]];
                }
            }
            
            [parameters removeObjectForKey:key];
        }
        
        for (NSString *key in parameters) {
            id parameter = parameters[key];
            
            if ([parameter isKindOfClass:[NSNumber class]])
                parameter = [parameter stringValue];
            
            [formData appendPartWithFormData:[parameter dataUsingEncoding:NSUTF8StringEncoding] name:key];
        }
    };
}

#pragma mark Makers

- (NSURLSessionDataTask * _Nonnull)make:(NSString * _Nonnull)method
                        requestWithPath:(NSString * _Nonnull)path
                                baseURL:(NSURL * _Nullable)baseURL
                                 params:(NSDictionary * _Nullable)immutableParams
                           extraHeaders:(NSDictionary * _Nullable)extraHeaders
                     suppressErrorAlert:(BOOL)supressErrorAlert
                            uploadBlock:(APIProgressBlock _Nullable)uploadBlock
                          downloadBlock:(APIProgressBlock _Nullable)downloadBlock
                            cacheOption:(APICacheOption)cacheOption
                             completion:(APIResponseBlock _Nullable)block
{
    self.method = method;
    self.path = path;
    self.baseURL = baseURL;
    self.parameters = immutableParams;
    self.extraHeaders = extraHeaders;
    self.suppressErrorAlert = supressErrorAlert;
    self.uploadBlock = uploadBlock;
    self.downloadBlock = downloadBlock;
    self.cacheOption = cacheOption;
    self.completionBlock = block;
    
    return [self makeRequest];
}

// simplified method in case you don't need to use all parameters from the method above
- (NSURLSessionDataTask * _Nonnull)make:(NSString * _Nonnull)method
                        requestWithPath:(NSString * _Nonnull)path
                                 params:(NSDictionary * _Nullable)immutableParams
                            cacheOption:(APICacheOption)cacheOption
                             completion:(APIResponseBlock _Nullable)block
{
    return [self make:method requestWithPath:path baseURL:nil params:immutableParams extraHeaders:nil suppressErrorAlert:NO uploadBlock:nil downloadBlock:nil cacheOption:cacheOption completion:block];
}

- (NSURLSessionDataTask *)makeRequest
{
    BOOL hasCache = NO;
    
    if (self.cacheOption == APICacheOptionBoth || self.cacheOption == APICacheOptionCacheOnly) { // if one of the options includes cache
        hasCache = [API returnCacheIfExistsForFileName:self.cacheFileName completion:self.completionBlock]; // this methods returns a boolean indicating if the file exists in cache and calls the block with the cached content if it exists
    }
    
    if (self.cacheOption == APICacheOptionBoth || self.cacheOption == APICacheOptionNetworkOnly || !hasCache) { // if one of the options including the request or if file not in cache, let's make the request
        
        NSMutableDictionary *parameters = self.parameters.mutableCopy;
        
        if (!self.baseURL) {
            self.baseURL = [NSURL URLWithString:APIBaseURL];
        }
        
        AFHTTPSessionManager *manager = [API sharedSessionManager]; // [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
        manager.baseURL = self.baseURL;
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        
        // authentication headers here
        
        if (self.extraHeaders) {
            for (NSString *key in self.extraHeaders.allKeys)
                [manager.requestSerializer setValue:self.extraHeaders[key] forHTTPHeaderField:key];
        }
        
        NSArray *dataParameters = [API identifyDataParametersInParameters:parameters]; // identifies parameters that are instances of NSData
        
        APIMultipartConstructionBlock multipartFormDataConstructionBlock;
        if (dataParameters.count > 0) { // requests with NSData parameters should be sent using multipart/form-data
            multipartFormDataConstructionBlock = [self multipartFormDataConstructionBlockWithDataParameters:dataParameters mutableParameters:parameters];
            parameters = nil;
        }
        
        NSURLSessionDataTask *task = [manager dataTaskWithHTTPMethod:self.method
                                                           URLString:self.path
                                                          parameters:parameters
                                           constructingBodyWithBlock:multipartFormDataConstructionBlock
                                                      uploadProgress:self.uploadBlock
                                                    downloadProgress:self.downloadBlock
                                                             success:[self requestSuccessBlock]
                                                             failure:[self requestFailureBlock]];
        [task resume];
        
        return task;
    }
    
    return nil;
}

@end
