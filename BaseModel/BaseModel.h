//
//  BaseModel.h
//
//  Created by Jota Melo on 8/21/15.
//  Copyright (c) 2015 Jota. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseModel : NSObject

@property (strong, nonatomic) NSDictionary *originalDict;
@property (strong, nonatomic) NSString *uid;

+ (instancetype)initWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
