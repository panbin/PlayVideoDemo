//
//  NSString+StringSizeWithFont.h
//  iDota
//
//  Created by dnnta on 13-11-16.
//  Copyright (c) 2013年 NightWish. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringSizeWithFont)

- (CGSize)sizeWithMyFont:(UIFont *)font;
- (CGSize)sizeWithMyFont:(UIFont *)font width:(CGFloat)width;

@end
