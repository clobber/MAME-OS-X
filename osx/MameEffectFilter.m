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

#import "MameEffectFilter.h"


#define MAME_STANDALONE_FILTERS 1

static CIKernel * sMameEffectKernel = nil;

@implementation MameEffectFilter

#if MAME_STANDALONE_FILTERS
+ (void)initialize
{
    [CIFilter registerFilterName: @"MameEffectFilter"  constructor: self
                 classAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                     
                     @"Mame Image Effect Filter", kCIAttributeFilterDisplayName,
                     
                     [NSArray arrayWithObjects:
                         kCICategoryColorAdjustment, kCICategoryVideo, kCICategoryStillImage,
                         kCICategoryInterlaced, kCICategoryNonSquarePixels,
                         nil],                              kCIAttributeFilterCategories,
                     
                     [NSDictionary dictionaryWithObjectsAndKeys:
                         nil],                               @"effectImage",

                     nil]];
}

+ (CIFilter *)filterWithName: (NSString *)name
{
    CIFilter  *filter;
    
    filter = [[self alloc] init];
    return [filter autorelease];
}
#endif

- (id) init;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    if (sMameEffectKernel == nil)
    {
        NSBundle * myBundle = [NSBundle bundleForClass: [self class]];
        NSString * kernelFile = [myBundle pathForResource: @"MameEffect"
                                                   ofType: @"cikernel"];
        NSString * code = [NSString stringWithContentsOfFile: kernelFile];
        NSArray * kernels = [CIKernel kernelsWithString: code];
        sMameEffectKernel = [[kernels objectAtIndex: 0] retain];
    }
    
    return self;
}

- (NSDictionary *) customAttributes;
{
    return [NSDictionary dictionary];
}

- (CIImage *) outputImage;
{
    NSDictionary * samplerOptions = [NSDictionary dictionaryWithObjectsAndKeys:
        kCISamplerFilterNearest, kCISamplerFilterMode,
        nil];
    CISampler * input = [CISampler samplerWithImage: inputImage
                                          options: samplerOptions];
    CISampler * effect = [CISampler samplerWithImage: effectImage
                                            options: samplerOptions];

    return [self apply: sMameEffectKernel, input, effect, @"definition",
        [input definition], nil];
}    

@end
