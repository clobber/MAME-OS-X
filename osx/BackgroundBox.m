//
//  BackgroundBox.m
//  mameosx
//
//  Created by Dave Dribin on 12/4/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "BackgroundBox.h"


@implementation BackgroundBox

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    NSColor * color = [NSColor colorWithCalibratedWhite: 0.90 alpha: 1.0];
    [color set];
    NSRectFill(rect);
}

@end
