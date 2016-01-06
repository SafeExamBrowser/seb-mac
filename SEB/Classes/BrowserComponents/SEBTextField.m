//
//  SEBTextField.m
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 28/05/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import "SEBTextField.h"

@implementation SEBTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (CGRect)editingRectForBounds:(CGRect)bounds
{
    CGRect textRect = [super editingRectForBounds:bounds];
    textRect.size.width += 6;
    return textRect;
}


- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    CGRect textRect = [super rightViewRectForBounds:bounds];
    textRect.origin.x -= 7;
    return textRect;
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
