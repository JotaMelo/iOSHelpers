//
//  GroupImageView.m
//
//  Created by Jota Melo on 7/20/15.
//  Copyright (c) 2015 Jota Melo. All rights reserved.
//

#import "JMGroupImageView.h"
#import "UIImageView+AFNetworking.h"

@interface JMGroupImageView ()

@end

@implementation JMGroupImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    [self reloadImages];
    self.layer.masksToBounds = YES;
}

- (void)setImages:(NSArray *)images
{
    _images = images;
    
    [self reloadImages];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
    
    self.layer.cornerRadius = cornerRadius;
}

- (void)reloadImages
{
    for (UIView *view in self.subviews) [view removeFromSuperview];
    
    CGFloat imageWidth = (self.frame.size.width / 2) - (self.spacing / 2);
    CGFloat imageHeight = (self.frame.size.height / 2) - (self.spacing / 2);
    
    if (self.images.count == 1) {
        [self addImageViewWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
                         imageOrURL:self.images[0]];
    } else if (self.images.count == 2) {
        [self addImageViewWithFrame:CGRectMake(0, 0, imageWidth, self.frame.size.height)
                         imageOrURL:self.images[0]];
        
        [self addImageViewWithFrame:CGRectMake(imageWidth + self.spacing, 0, imageWidth, self.frame.size.height)
                         imageOrURL:self.images[1]];
    } else if (self.images.count == 3) {
        [self addImageViewWithFrame:CGRectMake(0, 0, imageWidth, self.frame.size.height)
                         imageOrURL:self.images[0]];
        
        [self addImageViewWithFrame:CGRectMake(self.spacing + imageWidth, 0, imageWidth, imageHeight)
                         imageOrURL:self.images[1]];
        
        [self addImageViewWithFrame:CGRectMake(self.spacing + imageWidth, imageHeight + self.spacing, imageWidth, imageHeight)
                         imageOrURL:self.images[2]];
    } else if (self.images.count == 4) {
        [self addImageViewWithFrame:CGRectMake(0, 0, imageWidth, imageHeight)
                         imageOrURL:self.images[0]];
        
        [self addImageViewWithFrame:CGRectMake(0, imageHeight + self.spacing, imageWidth, imageHeight)
                         imageOrURL:self.images[1]];
        
        [self addImageViewWithFrame:CGRectMake(self.spacing + imageWidth, 0, imageWidth, imageHeight)
                         imageOrURL:self.images[2]];
        
        [self addImageViewWithFrame:CGRectMake(self.spacing + imageWidth, imageHeight + self.spacing, imageWidth, imageHeight)
                         imageOrURL:self.images[3]];
    }
}

- (void)addImageViewWithFrame:(CGRect)frame imageOrURL:(id)imageOrURL
{
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    
    if ([imageOrURL isKindOfClass:[UIImage class]])
        imageView.image = imageOrURL;
    else if ([imageOrURL isKindOfClass:[NSURL class]])
        [imageView setImageWithURL:imageOrURL];
    else if ([imageOrURL isKindOfClass:[NSString class]])
        [imageView setImageWithURL:[NSURL URLWithString:imageOrURL]];
    
    [self addSubview:imageView];
}

@end
