//
//  BaseModel.h
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseModel : NSObject <NSCopying>

@property (strong, nonatomic) NSString *modelDateFormat;
@property (strong, nonatomic) NSDictionary *originalDictionary;
@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@property (strong, nonatomic) NSNumber *uid;

+ (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end
