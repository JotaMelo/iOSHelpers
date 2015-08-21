//
//  GroupImageView.m
//
//  Created by Jota Melo on 7/20/15.
//  Copyright (c) 2015 Jota Melo. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface JMGroupImageView : UIView

@property (assign, nonatomic) IBInspectable CGFloat spacing;
@property (assign, nonatomic) IBInspectable CGFloat cornerRadius;
@property (strong, nonatomic) NSArray *images;

@end
