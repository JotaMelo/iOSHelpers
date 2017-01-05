//
//  API.h
//  v1.0
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef void(^APIRequestSuccessBlock)(NSURLSessionDataTask * _Nullable response, id _Nullable responseObject);
typedef void(^APIRequestFailureBlock)(NSURLSessionDataTask * _Nullable response, NSError * _Nullable error);
typedef void(^APIMultipartConstructionBlock)(id<AFMultipartFormData>  _Nonnull formData);
typedef void(^APIProgressBlock)(NSProgress * _Nonnull progress);
typedef void(^APIResponseBlock)(id _Nullable response, NSError * _Nullable error, BOOL cache);

typedef NS_ENUM(NSUInteger, APICacheOption) {
    APICacheOptionCacheOnly, // only use cache, if available. If not, makes the request
    APICacheOptionNetworkOnly, // ignores cache, only makes the request
    APICacheOptionBoth, // uses cache, if available, and makes the request
};

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const APIBaseURL;
FOUNDATION_EXPORT NSString * const APIErrorDomain;

FOUNDATION_EXPORT NSString * const APIAuthenticationHeadersDefaultsKey;

FOUNDATION_EXPORT NSString * const APIMethodGET;
FOUNDATION_EXPORT NSString * const APIMethodPOST;
FOUNDATION_EXPORT NSString * const APIMethodPUT;
FOUNDATION_EXPORT NSString * const APIMethodPATCH;
FOUNDATION_EXPORT NSString * const APIMethodDELETE;

NS_ASSUME_NONNULL_END

@interface API : NSObject

@property (strong, nonatomic, nonnull) NSString *method;
@property (strong, nonatomic, nonnull) NSString *path;
@property (strong, nonatomic, nullable) NSURL *baseURL;
@property (strong, nonatomic, nullable) NSDictionary *parameters;
@property (strong, nonatomic, nullable) NSDictionary *extraHeaders;

@property (assign, nonatomic) APICacheOption cacheOption;
@property (assign, nonatomic) BOOL suppressErrorAlert;

@property (copy, nonatomic, nullable) APIProgressBlock uploadBlock;
@property (copy, nonatomic, nullable) APIProgressBlock downloadBlock;
@property (copy, nonatomic, nullable) APIResponseBlock completionBlock;

@property (assign, nonatomic) BOOL shouldSaveCache;
@property (strong, nonatomic, nonnull) NSString *cacheFileName;

+ (void)logout;

#pragma mark - Helpers

+ (BOOL)checkForDataObjectsInParameters:(NSArray * _Nonnull)parameters;

+ (NSDictionary * _Nonnull)flattenDictionary:(NSDictionary * _Nonnull)dictionary;

+ (void)handleError:(NSError * _Nonnull)error withResponseObject:(id _Nullable)responseObject;

+ (void)showErrorMessage:(NSString * _Nonnull)errorMessage;

#pragma mark - HTTP

#pragma mark Blocks

- (APIRequestSuccessBlock _Nonnull)requestSuccessBlock;

- (APIRequestFailureBlock _Nonnull)requestFailureBlock;

- (APIMultipartConstructionBlock _Nonnull)multipartFormDataConstructionBlockWithParameters:(NSDictionary * _Nonnull)parameters;

#pragma mark Makers

/**
 Creates and returns an instance of `API` with the provided parameters
 
 @param method             The HTTP method to be used
 @param path               The path of the request
 @param baseURL            An option baseURL to be used with the path. If nil, uses the class' default baseURL
 @param parameters    A dictionary of parameters. If any of the values is of type NSData (or an array of NSData), the request will be sent as a multipart/form-data
 @param extraHeaders       These headers will be appended to the request
 @param suppressErrorAlert Should silence the default error alert
 @param uploadBlock        A block that reports the progress of the request's upload
 @param downloadBlock      A block that reports the progress of the request's download
 @param cacheOption        The cache option to be used for this request, check the definition in the header for more info
 @param block              A block called when the request in completed. It takes an id (the response object), NSError (the error of the request if any) and a BOOL (indicating if the request came from the cache)
 */
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

+ (instancetype _Nonnull)make:(NSString * _Nonnull)method
              requestWithPath:(NSString * _Nonnull)path
                   parameters:(NSDictionary * _Nullable)parameters
                  cacheOption:(APICacheOption)cacheOption
                   completion:(APIResponseBlock _Nullable)block;

/**
 Created and runs an `NSURLSessionDataTask` using the instance properties
 */
- (NSURLSessionDataTask * _Nonnull)makeRequest;

@end
