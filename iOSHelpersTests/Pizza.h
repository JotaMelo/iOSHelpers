//
//  Pizza.h
//  iOSHelpers
//
//  Created by Jota Melo on 21/09/16.
//
//

#import "BaseModel.h"

@interface Pizza : BaseModel

@property (assign, nonatomic) NSInteger pizzaID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *numberOfIngredients;

@end
