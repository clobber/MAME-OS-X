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

#import "CustomMameFilters.h"


@implementation MameInputCenterFilter

- (id) initWithFilter: (CIFilter *) filter;
{
    if ([super initWithFilter: filter] == nil)
        return nil;
    
    return self;
}

+ (MameInputCenterFilter *) filterWithFilter: (CIFilter *) filter;
{
    return [[[self alloc] initWithFilter: filter] autorelease];
}

- (CIImage *) filterFrame: (CIImage *) inputImage size: (NSSize) size;
{
    [mFilter setValue: [CIVector vectorWithX: size.width/2 Y: size.height/2]
               forKey: @"inputCenter"];
    return [super filterFrame: inputImage size: size];
}

@end



@implementation MameBumpDistortionFilter

- (id) init;
{
    if ([super initWithFilter: [CIFilter filterWithName: @"CIBumpDistortion"]] == nil)
        return nil;
    
    [mFilter setDefaults];
    [mFilter setValue: [NSNumber numberWithFloat: 75]  
               forKey: @"inputRadius"];
    [mFilter setValue: [NSNumber numberWithFloat:  3.0]  
               forKey: @"inputScale"];
    mCenterX = 0;
    
    return self;
}

+ (MameBumpDistortionFilter *) filter;
{
    return [[[self alloc] init] autorelease];
}

- (CIImage *) filterFrame: (CIImage *) frame size: (NSSize) size;
{
    mCenterX += 2;
    if (mCenterX > (size.width - 0))
        mCenterX = 0;
    
    [mFilter setValue: [CIVector vectorWithX: mCenterX Y: size.height/2]
               forKey: @"inputCenter"];
    return [super filterFrame: frame size: size];
}

@end

@implementation EffectFilter

- (id) initWithPath: (NSString *) path;
{
    NSURL * url = [NSURL fileURLWithPath: path];
    CIImage * effect = [CIImage imageWithContentsOfURL: url];
    CIFilter * tile = [CIFilter filterWithName: @"CIAffineTile"];
    [tile setDefaults];
    [tile setValue: effect forKey: @"inputImage"];
    [tile setValue: [NSAffineTransform transform] forKey: @"inputTransform"];
    CIImage * tiledEffect = [tile valueForKey: @"outputImage"];
    
    CIFilter * multiply = [CIFilter filterWithName: @"CIMultiplyBlendMode"];
    [multiply setValue: tiledEffect
                forKey: @"inputBackgroundImage"];
    return [super initWithFilter: multiply];
}

+ (EffectFilter *) effectWithPath: (NSString *) path;
{
    return [[[self alloc] initWithPath: path] autorelease];
}

@end

