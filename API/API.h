//
//  API.h
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RequestBlock)(id response, NSError *error, BOOL cache);

typedef NS_ENUM(NSUInteger, CacheOption) {
    CacheOptionCacheOnly, // only use cache, if available. If not, makes the request
    CacheOptionNetworkOnly, // ignores cache, only makes the request
    CacheOptionBoth, // uses cache, if available, and makes the request
};

@interface API : NSObject

+ (void)clearCache;

@end
