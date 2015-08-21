//
//  API.h
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RequestBlock)(id response, NSError *error, BOOL cache);

typedef NS_ENUM(NSUInteger, CacheOption) {
    CacheOptionCacheOnly, //usa somente o cache, se disponível
    CacheOptionNetworkOnly, //ignora o cache, faz somente a requisição
    CacheOptionBoth, //usa o cache, se disponível, e faz a requisição
};

@interface API : NSObject

@end
