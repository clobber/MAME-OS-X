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
#import <QuartzCore/QuartzCore.h>
#include "render.h"

@class MameTextureTable;

@class MameOpenGLRenderer;

@interface MameRenderer : NSObject
{
    MameOpenGLRenderer * mOpenGLRenderer;
    MameTextureTable * mTextureTable;
    NSSize mCurrentFrameSize;
    NSSize mCenteringOffset;

    NSOpenGLContext * mGlContext;
    CVOpenGLBufferRef mCurrentFrame;
    CVOpenGLTextureCacheRef mFrameTextureCache;
    CVOpenGLTextureRef mCurrentFrameTexture;
}

- (CVOpenGLTextureRef) currentFrameTexture;

- (void) osd_init: (NSOpenGLContext *) mameViewContext
           format: (NSOpenGLPixelFormat *) mameViewFormat
             size: (NSSize) size;

- (void) osd_exit;

- (void) renderFrame: (const render_primitive_list *) primitives
            withSize: (NSSize) size;

- (void) setOpenGLContext: (NSOpenGLContext *) context
              pixelFormat: (NSOpenGLPixelFormat *) pixelFormat;

- (BOOL) linearFilter;
- (void) setLinearFilter: (BOOL) linearFilter;

@end
