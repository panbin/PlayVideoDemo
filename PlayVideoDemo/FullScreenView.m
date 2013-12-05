//
//  FullScreenView.m
//  PlayVideoDemo
//
//  Created by panbin on 13-12-5.
//  Copyright (c) 2013年 Handpay. All rights reserved.
//

#import "FullScreenView.h"

@implementation FullScreenView

- (id)init
{
    if ((self = [super init])) {
        self.autoresizesSubviews = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
