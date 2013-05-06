//
//  SEBTextField.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.05.13.
//
//

#import "SEBTextField.h"

@implementation SEBTextField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

// Fixes a bug in OS X 10.7 Lion with not properly calculating size of
// NSTextField depending on wrapped text inside,
// reporting the dimensions of the text if laid out in on a single line
// Thank you Monolo!
-(NSSize)intrinsicContentSize
{
    if ( ![self.cell wraps] ) {
        return [super intrinsicContentSize];
    }
    
    NSRect frame = [self frame];
    
    CGFloat width = frame.size.width;
    
    // Make the frame very high, while keeping the width
    frame.size.height = CGFLOAT_MAX;
    
    // Calculate new height within the frame
    // with practically infinite height.
    CGFloat height = [self.cell cellSizeForBounds: frame].height;
    
    return NSMakeSize(width, height);
}


@end
