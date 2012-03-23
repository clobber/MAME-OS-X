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

#import <Cocoa/Cocoa.h>

/*
#if defined(__cplusplus)
extern "C" {
#endif
    
#define class klass
*/
#include "render.h"
#include "palette.h"
/*
#undef class
    
#if defined(__cplusplus)
}
#endif
*/
#import <QuartzCore/QuartzCore.h>

@interface MameOpenGLTexture : NSObject
{
	render_texinfo			texinfo;			// copy of the texture info
	UINT32				hash;				// hash value for the texture
	UINT32				flags;				// rendering flags
	float				ustart, ustop;			// beginning/ending U coordinates
	float				vstart, vstop;			// beginning/ending V coordinates
	int				rawwidth, rawheight;		// raw width/height of the texture
	int				type;				// what type of texture are we?
	int				borderpix;			// do we have a 1 pixel border?
	int				xprescale;			// what is our X prescale factor?
	int				yprescale;			// what is our Y prescale factor?
    
    CVPixelBufferRef mPixelBuffer;
    CVOpenGLTextureRef mCVTexture;
}

+ (UINT32) computeHashForPrimitive: (const render_primitive *) primitive;

- (id) initWithPrimitive: (const render_primitive *) primitive
            textureCache: (CVOpenGLTextureCacheRef) textureCache;

- (BOOL) isEqualToPrimitive: (const render_primitive *) primitive;

- (UINT32) sequenceId;

- (void) computeSize;

- (void) setData: (CVOpenGLTextureCacheRef) textureCache;

- (void) updateData: (const render_primitive *) primitive
       textureCache: (CVOpenGLTextureCacheRef) textureCache;

- (void) renderPrimitive: (const render_primitive * ) primitive
         centeringOffset: (NSSize) mCenteringOffset
            linearFilter: (BOOL) linearFilter;

@end
