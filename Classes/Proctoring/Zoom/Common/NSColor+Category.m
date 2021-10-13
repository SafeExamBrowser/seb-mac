//
//  NSColor+Category.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "NSColor+Category.h"

@implementation NSColor (Category)

+ (NSColor*)colorWithRGBString:(NSString*)colorString
{
    NSColor* color = nil;
    if ([colorString length]>=6)
    {
        float red = 0.0;
        float green = 0.0;
        float blue = 0.0;
        float alpha = 1.0;
        unichar c = [colorString characterAtIndex:0];
        red += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0)*16;
        c = [colorString characterAtIndex:1];
        red += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0);
        red /= 255.0;
        
        c = [colorString characterAtIndex:2];
        green += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0)*16;
        c = [colorString characterAtIndex:3];
        green += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0);
        green /= 255.0;
        
        c = [colorString characterAtIndex:4];
        blue += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0)*16;
        c = [colorString characterAtIndex:5];
        blue += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0);
        blue /= 255.0;
        
        if ([colorString length]>=8)
        {
            c = [colorString characterAtIndex:6];
            alpha += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0)*16;
            c = [colorString characterAtIndex:7];
            alpha += (c - '0' >=0 && c - '9' <=0? c - '0':c - 'a' >=0 && c - 'f' <=0? c - 'a' + 10:c - 'A' >=0 && c - 'F' <=0? c - 'A' + 10:0);
            alpha /= 255.0;
        }
        
        color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
    }
    
    return color;
}

@end
