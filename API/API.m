//
//  API.m
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import "API.h"
#import "AFNetworking.h"

#define BASE_URL @"http://whatever.com/api/"

@implementation API

NSString *const GET     = @"GET";
NSString *const POST    = @"POST";
NSString *const PUT     = @"PUT";
NSString *const PATCH   = @"PATCH";
NSString *const DELETE  = @"DELETE";


#pragma mark - API methods

//metodos da API aqui

#pragma mark - Cache

+ (NSString *)cacheFileNameWithPath:(NSString *)path
                          andParams:(NSDictionary *)params
{
    NSMutableString *fileName = path.mutableCopy;
    
    for (NSString *key in params.allKeys)
        [fileName appendFormat:@"_%@", params[key]];
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"-"].mutableCopy;
    
    return fileName;
}

+ (BOOL)returnCacheIfExistsForFileName:(NSString *)cacheFileName
                              andBlock:(RequestBlock)block
{
    NSURL *cacheURL = [self getFileURL:cacheFileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cacheURL path]]) {
        NSData *data = [[NSMutableData alloc] initWithContentsOfURL:cacheURL];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSMutableDictionary *response = [[NSMutableDictionary alloc] initWithDictionary:[unarchiver decodeObjectForKey:@"data"]];
        
        block(response[@"data"], nil, YES);
        
        return YES;
    }
    
    return NO;
}

+ (void)writeData:(id)data
      toCacheFile:(NSString *)cacheFileName
{
    NSURL *cacheURL = [self getFileURL:cacheFileName];
    NSMutableData *fileData = [[NSMutableData alloc] init];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:fileData];
    [archiver encodeObject:@{@"data": data} forKey:@"data"];
    [archiver finishEncoding];

    [fileData writeToURL:cacheURL atomically:YES];
}

+ (NSURL *)getFileURL:(NSString *)fileName
{
    NSURL *documentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                        inDomains:NSUserDomainMask] lastObject];
    NSURL *fileURL = [documentsDirectory
                      URLByAppendingPathComponent:fileName];
    return fileURL;
}

#pragma mark - HTTP

+ (void)make:(NSString *)method
requestWithPath:(NSString *)path
      params:(NSDictionary *)immutableParams
extraHeaders:(NSDictionary *)extraHeaders
suppressErrorAlert:(BOOL)supressErrorAlert
    progressBlock:(void(^)(float progress))progressBlock
 cacheOption:(CacheOption)cacheOption
    andBlock:(RequestBlock)block
{
    NSString *cacheFileName = [self cacheFileNameWithPath:path andParams:immutableParams]; //gera o nome do arquivo para cache
    BOOL hasCache = NO;
    
    if (cacheOption == CacheOptionBoth || cacheOption == CacheOptionCacheOnly) //se for uma das opções que inclui cache
        hasCache = [self returnCacheIfExistsForFileName:cacheFileName andBlock:block]; //esse metodo retorna um BOOL indicando se o arquivo existe no cache e chama o block com o conteudo do cache caso exista
    
    if (cacheOption == CacheOptionBoth || cacheOption == CacheOptionNetworkOnly || !hasCache) { //se for uma das opções que inclui a requisição, ou caso o cache não exista, faz a requisição
        void(^successBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            [self writeData:responseObject toCacheFile:cacheFileName]; //requisição ok, salva no cache

            if (block) block(responseObject, nil, NO);
        };
        
        void(^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
            if (!supressErrorAlert)
                [[[UIAlertView alloc] initWithTitle:@"Erro" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            
            if (block) block(operation.responseObject, error, NO);
        };
        
        NSMutableDictionary *params = immutableParams.mutableCopy;
        
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        //colocar aqui os parametros/headers de autenticação necessários se for o caso
        //para adicionar um header, ex:
        //[manager.requestSerializer setValue:@"ccf4a12997a2c63ba278121e07a4c7fd363732ad4044bd5fc882103a9de6eeb1" forHTTPHeaderField:@"X-Auth-Token"];
        
        if (extraHeaders) {
            for (NSString *key in extraHeaders.allKeys)
                [manager.requestSerializer setValue:extraHeaders[key] forHTTPHeaderField:key];
        }
        
        AFHTTPRequestOperation *op = [manager HTTPRequestOperationWithHTTPMethod:method URLString:path parameters:params success:successBlock failure:failureBlock];

        if (progressBlock)
            [op setUploadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
                progressBlock((float)totalBytesRead / totalBytesExpectedToRead);
            }];

        [op start];
    }
}

//metodo simplificado caso não precise usar todos os parametros do metodo acima
+ (void)make:(NSString *)method
requestWithPath:(NSString *)path
      params:(NSDictionary *)immutableParams
 cacheOption:(CacheOption)cacheOption
    andBlock:(RequestBlock)block
{
    [self make:method requestWithPath:path params:immutableParams extraHeaders:nil suppressErrorAlert:NO progressBlock:nil cacheOption:cacheOption andBlock:block];
}

@end
