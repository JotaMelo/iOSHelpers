//
//  User.h
//  iOSHelpers
//
//  Created by Jota Melo on 21/09/16.
//
//

#import "BaseModel.h"
#import "Pizza.h"

@protocol Pizza
@end

@interface User : BaseModel

@property (strong, nonatomic) NSString *userName;
@property (strong, nonatomic) NSString *email;
@property (assign, nonatomic) BOOL isFirstLogin;
@property (strong, nonatomic) NSDate *registerDate;
@property (strong, nonatomic) Pizza *favoritePizza;
@property (strong, nonatomic) NSArray<Pizza *><Pizza> *orderedPizzas;

@end
