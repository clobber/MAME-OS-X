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

#import "MameTextureTable.h"
#import "MameOpenGLTexture.h"


@implementation MameTextureTable

- (id) initWithContext: (NSOpenGLContext *) context
           pixelFormat: (NSOpenGLPixelFormat *) pixelFormat;
{
    if ([super init] == nil)
        return nil;
    
    CVReturn rc =
        CVOpenGLTextureCacheCreate(NULL, 0, (CGLContextObj) [context CGLContextObj],
                                   (CGLPixelFormatObj) [pixelFormat CGLPixelFormatObj],
                                   0, &mTextureCache);
    if (rc != kCVReturnSuccess)
        return nil;

    mTextures = [[NSMutableArray alloc] init];
    
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mTextures release];
    CVOpenGLTextureCacheRelease(mTextureCache);
    
    mTextures = nil;
    [super dealloc];
}

- (MameOpenGLTexture *) findTextureForPrimitive: (const render_primitive *) primitive;
{
    MameOpenGLTexture * texture;
    NSEnumerator * i = [mTextures objectEnumerator];
    while (texture = [i nextObject])
    {
        if ([texture isEqualToPrimitive: primitive])
            return texture;
    }
    return nil;
}

- (MameOpenGLTexture *) findOrCreateTextureForPrimitive: (const render_primitive *) primitive;
{
    MameOpenGLTexture * texture = [self findTextureForPrimitive: primitive];
    if (texture == nil)
    {
        texture = [[MameOpenGLTexture alloc] initWithPrimitive: primitive
                                                  textureCache: mTextureCache];
        [texture autorelease];
        [mTextures addObject: texture];
    }
    return texture;
}


- (void) updateTextureForPrimitive: (const render_primitive *) primitive;
{
    MameOpenGLTexture * texture = [self findOrCreateTextureForPrimitive: primitive];
    if ([texture sequenceId] != primitive->texture.seqid)
    {
        [texture updateData: primitive textureCache: mTextureCache];
    }
}

- (void) performHousekeeping;
{
    CVOpenGLTextureCacheFlush(mTextureCache, 0);
}

@end
