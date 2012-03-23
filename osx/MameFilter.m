/*
 * Copyright (c) 2006-2007 Dave Dribin
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "MameFilter.h"


@implementation MameFilter

- (id) initWithFilter: (CIFilter *) filter;
{
    if ([super init] == nil)
        return nil;
    
    mFilter = [filter retain];
    mCrop = [[CIFilter filterWithName: @"CICrop"] retain];

    return self;
}

- (id) init
{
    return [self initWithFilter: nil];
}

+ (MameFilter *) filterWithFilter: (CIFilter *) filter;
{
    return [[[self alloc] initWithFilter: filter] autorelease];
}

- (void) dealloc;
{
    [mFilter release];
    [mCrop release];
    [super dealloc];
}

- (CIImage *) filterFrame: (CIImage *) frame size: (NSSize) size;
{
    if (mFilter == nil)
        return frame;

    [mFilter setValue: frame forKey:@"inputImage"];
    frame = [mFilter valueForKey: @"outputImage"];
    
    [mCrop setValue: frame forKey: @"inputImage"];
    [mCrop setValue: [CIVector vectorWithX: 0  Y: 0
                                         Z: size.width W: size.height]
                  forKey: @"inputRectangle"];
    frame = [mCrop valueForKey: @"outputImage"];
    return frame;
}

@end
