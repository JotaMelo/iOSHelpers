//
//  API.m
//  v1.0
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "API.h"
#import "APICacheManager.h"
#import "AFNetworking.h"

NSString * const APIBaseURL       = @"http://example.com";
NSString * const APIPath          = @"/api/v1/";
NSString * const APIErrorDomain   = @"com.app.error";

NSString * const APIAuthenticationHeadersDefaultsKey = @"authenticationHeaders";

NSString * const APIMethodGET     = @"GET";
NSString * const APIMethodPOST    = @"POST";
NSString * const APIMethodPUT     = @"PUT";
NSString * const APIMethodPATCH   = @"PATCH";
NSString * const APIMethodDELETE  = @"DELETE";


@interface API ()

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;
@property (readonly, nonatomic) NSArray<NSString *> *authenticationHeaders;

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shouldSaveCache = YES;
    }
    return self;
}

+ (NSURLSessionDataTask *)exampleRequestwithBlock:(APIResponseBlock)block
{
    API *request = [API make:APIMethodPOST requestWithPath:@"login" parameters:@{@"user": @"jota", @"senha": @"mansaothugstronda"} cacheOption:APICacheOptionBoth completion:block];
    request.shouldSaveCache = NO;
    
    return [request makeRequest];
}

#pragma mark - Accessors

- (NSURL *)baseURL
{
    if (_baseURL) {
        return _baseURL;
    } else {
        NSURL *baseURL = [NSURL URLWithString:APIBaseURL];
        return [baseURL URLByAppendingPathComponent:APIPath];
    }
}

- (NSArray<NSString *> *)authenticationHeaders
{
    return @[@"access-token", @"client", @"uid"];
}

- (NSString *)cacheFileName
{
    if (!_cacheFileName) {
        _cacheFileName = [APICacheManager.sharedManager cacheFileNameWithPath:self.path method:self.method parameters:self.parameters];
    }
    
    return _cacheFileName;
}


#pragma mark - Helpers

+ (void)logout
{
    for (NSString *header in [API new].authenticationHeaders) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:header];
    }
    
    [NSUserDefaults.standardUserDefaults synchronize];
}

+ (NSArray<NSString *> *)mimeTypeForData:(NSData *)data
{
    uint8_t c;
    [data getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @[@"image/jpeg", @".jpg"];
            break;
        case 0x89:
            return @[@"image/png", @".png"];
            break;
        case 0x47:
            return @[@"image/gif", @".gif"];
            break;
        case 0x49:
        case 0x4D:
            return @[@"image/tiff", @".tiff"];
            break;
        case 0x25:
            return @[@"application/pdf", @".pdf"];
            break;
        case 0xD0:
            return @[@"application/vnd", @""];
            break;
        case 0x46:
            return @[@"text/plain", @".txt"];
            break;
        default:
            return @[@"application/octet-stream", @""];
    }
    
    return nil;
}

+ (void)handleError:(NSError * _Nonnull)error withResponseObject:(id _Nullable)responseObject
{
    NSString *errorMessage;
    
    if ([responseObject isKindOfClass:[NSDictionary class]] && [responseObject[@"errors"] count] > 0) {
        errorMessage = responseObject[@"errors"][0];
    } else {
        errorMessage = error.localizedDescription;
    }
    
    [API showErrorMessage:errorMessage];
}

+ (void)showErrorMessage:(NSString * _Nonnull)errorMessage
{
#if TARGET_OS_IOS
    if ([[UIApplication sharedApplication].keyWindow isMemberOfClass:[UIWindow class]]) {  // don't show alert on top of another alert
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Erro", @"") message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#pragma clang pop
    }
#endif
}

+ (BOOL)checkForDataObjectsInParameters:(NSArray *)parameters
{
    for (id object in parameters) {
        if ([object isKindOfClass:[NSData class]]) {
            return YES;
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            BOOL hasData = [self checkForDataObjectsInParameters:[object allValues]];
            
            if (hasData) {
                return YES;
            }
        } else if ([object isKindOfClass:[NSArray class]]) {
            BOOL hasData = [self checkForDataObjectsInParameters:object];
            
            if (hasData) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (NSDictionary *)flattenDictionary:(NSDictionary *)dictionary
{
    return [self flattenDictionary:dictionary keyString:nil];
}

+ (NSDictionary *)flattenDictionary:(NSDictionary *)dictionary keyString:(NSString *)keyString
{
    NSMutableDictionary *flattenedDictionary = @{}.mutableCopy;
    
    for (NSString *key in dictionary) {
        id value = dictionary[key];
        
        NSString *newKey;
        if (keyString) {
            newKey = [NSString stringWithFormat:@"%@[%@]", keyString, key];
        } else {
            newKey = key;
        }
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *flattenedSubDictionary = [self flattenDictionary:value keyString:newKey];
            [flattenedDictionary addEntriesFromDictionary:flattenedSubDictionary];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSDictionary *flattenedSubDictionary = [self flattenArray:value keyString:newKey];
            [flattenedDictionary addEntriesFromDictionary:flattenedSubDictionary];
        } else {
            flattenedDictionary[newKey] = value;
        }
    }
    
    return flattenedDictionary;
}

+ (NSDictionary *)flattenArray:(NSArray *)array keyString:(NSString *)keyString
{
    NSMutableDictionary *flattenedDictionary = @{}.mutableCopy;
    
    for (int i = 0; i < array.count; i++) {
        id value = array[i];
        
        NSString *newKey = [NSString stringWithFormat:@"%@[%d]", keyString, i];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSDictionary *flattenedSubDictionary = [self flattenArray:value keyString:newKey];
            [flattenedDictionary addEntriesFromDictionary:flattenedSubDictionary];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *flattenedSubDictionary = [self flattenDictionary:value keyString:newKey];
            [flattenedDictionary addEntriesFromDictionary:flattenedSubDictionary];
        } else {
            flattenedDictionary[newKey] = value;
        }
    }
    
    return flattenedDictionary;
}

#pragma mark - HTTP

#pragma mark Blocks

- (APIRequestSuccessBlock)requestSuccessBlock
{
    return ^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"\n\n%@ %@", self.method, task.response);
        NSLog(@"%@", responseObject);
        
        if (self.shouldSaveCache) {
            [APICacheManager.sharedManager writeData:responseObject toCacheFile:self.cacheFileName]; // request ok, saves it in cache
        }
        
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        for (NSString *headerName in self.authenticationHeaders) {
            if (response.allHeaderFields[headerName]) {
                if (![NSUserDefaults.standardUserDefaults objectForKey:APIAuthenticationHeadersDefaultsKey]) {
                    [NSUserDefaults.standardUserDefaults setObject:@{} forKey:APIAuthenticationHeadersDefaultsKey];
                }
                
                NSMutableDictionary *storedAuthenticationHeaders = [[NSUserDefaults.standardUserDefaults objectForKey:APIAuthenticationHeadersDefaultsKey] mutableCopy];
                storedAuthenticationHeaders[headerName] = response.allHeaderFields[headerName];
                [NSUserDefaults.standardUserDefaults setObject:storedAuthenticationHeaders forKey:APIAuthenticationHeadersDefaultsKey];
            }
        }
        
        if (self.completionBlock) {
            if (NSThread.isMainThread) {
                self.completionBlock(responseObject, nil, NO);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.completionBlock(responseObject, nil, NO);
                });
            }
        }
    };
}

- (APIRequestFailureBlock)requestFailureBlock
{
    return ^(NSURLSessionDataTask *task, NSError *error) {
        // ignore error triggered when task is cancelled
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            return;
        }
        
        // can't get the responseObject directly in AFNetworking 3.0, so do that manually
        NSData *responseData = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
        id responseObject;
        
        if (responseData) {
            NSError *error;
            responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
            
            if (error) {
                responseObject = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            }
        }
        
        if (!self.suppressErrorAlert) {
            [API handleError:error withResponseObject:responseObject];
        }
        
        NSLog(@"\n\n%@ %@", self.method, task.response);
        NSLog(@"%@", responseObject);
        
        if (self.completionBlock) {
            if (NSThread.isMainThread) {
                self.completionBlock(responseObject, error, NO);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.completionBlock(responseObject, error, NO);
                });
            }
        }
    };
}

- (APIMultipartConstructionBlock)multipartFormDataConstructionBlockWithParameters:(NSDictionary *)parameters
{
    return ^(id<AFMultipartFormData>  _Nonnull formData) {
        for (id key in parameters) {
            id parameter = parameters[key];
            
            if ([parameter isKindOfClass:[NSData class]]) {
                NSString *fixedKey = [[key stringByReplacingOccurrencesOfString:@"[" withString:@""] stringByReplacingOccurrencesOfString:@"]" withString:@""];
                
                NSArray<NSString *> *mimeType = [API mimeTypeForData:parameter];
                [formData appendPartWithFileData:parameter name:key fileName:[fixedKey stringByAppendingString:mimeType.lastObject] mimeType:mimeType.firstObject];
            } else if (parameter != [NSNull null]) {
                if ([parameter isKindOfClass:[NSNumber class]]) {
                    parameter = [parameter stringValue];
                }
                
                [formData appendPartWithFormData:[parameter dataUsingEncoding:NSUTF8StringEncoding] name:key];
            }
        }
    };
}

#pragma mark Makers

+ (instancetype _Nonnull)make:(NSString * _Nonnull)method
              requestWithPath:(NSString * _Nonnull)path
                      baseURL:(NSURL * _Nullable)baseURL
                   parameters:(NSDictionary * _Nullable)parameters
                 extraHeaders:(NSDictionary * _Nullable)extraHeaders
           suppressErrorAlert:(BOOL)suppressErrorAlert
                  uploadBlock:(APIProgressBlock _Nullable)uploadBlock
                downloadBlock:(APIProgressBlock _Nullable)downloadBlock
                  cacheOption:(APICacheOption)cacheOption
                   completion:(APIResponseBlock _Nullable)block;
{
    API *request = [API new];
    request.method = method;
    request.path = path;
    request.baseURL = baseURL;
    request.parameters = parameters;
    request.extraHeaders = extraHeaders;
    request.suppressErrorAlert = suppressErrorAlert;
    request.uploadBlock = uploadBlock;
    request.downloadBlock = downloadBlock;
    request.cacheOption = cacheOption;
    request.completionBlock = block;
    
    return request;
}

// simplified method in case you don't need to use all parameters from the method above
+ (instancetype _Nonnull)make:(NSString * _Nonnull)method
              requestWithPath:(NSString * _Nonnull)path
                   parameters:(NSDictionary * _Nullable)parameters
                  cacheOption:(APICacheOption)cacheOption
                   completion:(APIResponseBlock _Nullable)block;
{
    return [self make:method requestWithPath:path baseURL:nil parameters:parameters extraHeaders:nil suppressErrorAlert:NO uploadBlock:nil downloadBlock:nil cacheOption:cacheOption completion:block];
}

- (NSURLSessionDataTask *)makeRequest
{
    BOOL hasCache = NO;
    
    if (self.cacheOption == APICacheOptionBoth || self.cacheOption == APICacheOptionCacheOnly) { // if one of the options includes cache
        hasCache = [APICacheManager.sharedManager callBlock:self.completionBlock ifCacheExistsForFileName:self.cacheFileName]; // this methods returns a boolean indicating if the file exists in cache and calls the block with the cached content if it exists
    }
    
    if (self.cacheOption == APICacheOptionBoth || self.cacheOption == APICacheOptionNetworkOnly || !hasCache) { // if one of the options including the request or if file not in cache, let's make the request
        
        NSMutableDictionary *parameters = self.parameters.mutableCopy;
        
        AFHTTPSessionManager *manager = [API sharedSessionManager];
        manager.baseURL = self.baseURL;
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
        
        for (NSString *headerName in self.authenticationHeaders) {
            NSString *headerValue = [NSUserDefaults.standardUserDefaults objectForKey:APIAuthenticationHeadersDefaultsKey][headerName];
            if (headerValue) {
                [manager.requestSerializer setValue:headerValue forHTTPHeaderField:headerName];
            }
        }
        
        if (self.extraHeaders) {
            for (NSString *key in self.extraHeaders.allKeys) {
                [manager.requestSerializer setValue:self.extraHeaders[key] forHTTPHeaderField:key];
            }
        }
        
        BOOL hasDataParameters = [API checkForDataObjectsInParameters:parameters.allValues];
        
        APIMultipartConstructionBlock multipartFormDataConstructionBlock;
        if (hasDataParameters) { // requests with NSData parameters should be sent using multipart/form-data
            NSDictionary *flattenedParameters = [API flattenDictionary:parameters];
            multipartFormDataConstructionBlock = [self multipartFormDataConstructionBlockWithParameters:flattenedParameters];
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
