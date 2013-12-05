//
//  NSString+StringSizeWithFont.m
//  iDota
//
//  Created by dnnta on 13-11-16.
//  Copyright (c) 2013年 NightWish. All rights reserved.
//

#import "NSString+StringSizeWithFont.h"

@implementation NSString (StringSizeWithFont)

#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1

- (CGSize)sizeWithMyFont:(UIFont *)font
{
    if ([self respondsToSelector:@selector(sizeWithAttributes:)]) {
        CGSize size = [self sizeWithAttributes:@{NSFontAttributeName: font}];
        return CGSizeMake(ceilf(size.width), ceilf(size.height));
    } else {
        return [self sizeWithFont:font];
    }
}

- (CGSize)sizeWithMyFont:(UIFont *)font width:(CGFloat)width
{
    CGSize size;
    
    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        CGRect rect = [self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: font}
                                         context:nil];
        size = CGSizeMake(ceilf(rect.size.width), ceil(rect.size.height));
    } else {
        size = [self sizeWithFont:font
                constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                    lineBreakMode:NSLineBreakByCharWrapping];
    }
    
    return size;
}

#else 

- (CGSize)sizeWithMyFont:(UIFont *)font
{
    if ([self respondsToSelector:@selector(sizeWithAttributes:)]) {
        CGSize size = [self sizeWithFont:font];
        return CGSizeMake(ceilf(size.width), ceilf(size.height));
    } else {
        return [self sizeWithFont:font];
    }
}

- (CGSize)sizeWithMyFont:(UIFont *)font width:(CGFloat)width
{
    CGSize size;
    
    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        size = [self sizeWithFont:font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)];
    } else {
        size = [self sizeWithFont:font
                constrainedToSize:CGSizeMake(width, CGFLOAT_MAX)
                    lineBreakMode:NSLineBreakByCharWrapping];
    }
    
    return size;
}

#endif

@end
