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

#import "MameOpenGLTexture.h"
#import "MameTextureConverter.h"

@interface MameOpenGLTexture (Private)

@end

static void cv_assert(CVReturn cr, NSString * message)
{
    if (cr != kCVReturnSuccess)
        NSLog(@"Core video returned: %d: %@", cr, message);
}

@implementation MameOpenGLTexture

+ (UINT32) computeHashForPrimitive: (const render_primitive *) primitive;
{
    const render_texinfo * texinfo = &primitive->texture;
    UINT32 flags = primitive->flags;
    return ((UINT32*)texinfo->base)[0] ^ (flags & (PRIMFLAG_BLENDMODE_MASK | PRIMFLAG_TEXFORMAT_MASK));
}

- (id) initWithPrimitive: (const render_primitive *) primitive
            textureCache: (CVOpenGLTextureCacheRef) textureCache;
{
    if ([super init] == nil)
        return nil;
    
    hash = [MameOpenGLTexture computeHashForPrimitive: primitive];
    flags = primitive->flags;
    texinfo = primitive->texture;
    xprescale = 1;
    yprescale = 1;
    
    mPixelBuffer = NULL;
    mCVTexture = NULL;
    
    [self computeSize];
    [self setData: textureCache];
   
    return self;
}

- (void) dealloc;
{
    if (mPixelBuffer != NULL)
    {
        CVPixelBufferRelease(mPixelBuffer);
        mPixelBuffer = NULL;
    }
    
    if (mCVTexture != NULL)
    {
        CVOpenGLTextureRelease(mCVTexture);
        mCVTexture = NULL;
    }
    
    [super dealloc];
}

- (BOOL) isEqualToPrimitive: (const render_primitive *) primitive;
{
    UINT32 primitiveHash = [MameOpenGLTexture computeHashForPrimitive: primitive];
    if ((hash == primitiveHash) &&
        (texinfo.base == primitive->texture.base) &&
        (texinfo.width == primitive->texture.width) &&
        (texinfo.height == primitive->texture.height) &&
        (((flags ^ primitive->flags) & (PRIMFLAG_BLENDMODE_MASK | PRIMFLAG_TEXFORMAT_MASK)) == 0))
    {
        return YES;
    }
    return NO;
}

- (UINT32) sequenceId;
{
    return texinfo.seqid;
}

- (void) computeSize;
{
    UINT32 texwidth = texinfo.width;
    UINT32 texheight = texinfo.height;

    int finalheight = texheight;
    int finalwidth = texwidth;
    
    // if we're above the max width/height, do what?
    if (finalwidth > 2048 || finalheight > 2048)
    {
        static int printed = FALSE;
        if (!printed) fprintf(stderr, "Texture too big! (wanted: %dx%d, max is %dx%d)\n", finalwidth, finalheight, 2048, 2048);
        printed = TRUE;
    }
    
    // compute the U/V scale factors
    ustart = 0.0f;
    ustop = (float)texwidth / (float)finalwidth;
    vstart = 0.0f;
    vstop = (float)texheight / (float)finalheight;
    
    // set the final values
    rawwidth = finalwidth;
    rawheight = finalheight;
}

- (void) setData: (CVOpenGLTextureCacheRef) textureCache;
{
    const render_texinfo * texsource = &texinfo;
    UINT32 *dst32, *dbuf;
    int x, y;

    if (mPixelBuffer == NULL)
    {
        cv_assert(CVPixelBufferCreate(NULL, rawwidth,
                                      rawheight,
                                      PixelBuffer::kPixelFormat,
                                      NULL, &mPixelBuffer),
                  @"Could not create pixle buffer");
    }
    
    int texformat = PRIMFLAG_GET_TEXFORMAT(flags);
    
    cv_assert(CVPixelBufferLockBaseAddress(mPixelBuffer, 0),
              @"Could not lock pixel buffer");
    
    PixelBuffer pixelBuffer(CVPixelBufferGetBaseAddress(mPixelBuffer),
                            CVPixelBufferGetBytesPerRow(mPixelBuffer));
    
    if (texformat == TEXFORMAT_ARGB32)
    {
        MameARGB32Texture cppTexture(texsource);
        convertTexture(cppTexture, pixelBuffer);
    }
    else if (texformat == TEXFORMAT_PALETTE16)
    {
        MamePalette16Texture cppTexture(texsource);
        convertTexture(cppTexture, pixelBuffer);
    }
    else if (texformat == TEXFORMAT_RGB15)
    {
        if (texsource->palette != NULL)
        {
            MamePaletteRGB15Texture cppTexture(texsource);
            convertTexture(cppTexture, pixelBuffer);
        }
        else
        {
            MameRGB15Texture cppTexture(texsource);
            convertTexture(cppTexture, pixelBuffer);
        }
    }
    else if (texformat == TEXFORMAT_RGB32)
    {
        if (texsource->palette != NULL)
        {
            MamePaletteRGB32Texture cppTexture(texsource);
            convertTexture(cppTexture, pixelBuffer);
        }
        else
        {
            MameRGB32Texture cppTexture(texsource);
            convertTexture(cppTexture, pixelBuffer);
        }
    }
    else
    {
        NSLog(@"Unknown texture blendmode=%d format=%d\n", PRIMFLAG_GET_BLENDMODE(flags), 
              PRIMFLAG_GET_TEXFORMAT(flags));
        cv_assert(CVPixelBufferUnlockBaseAddress(mPixelBuffer, 0),
                  @"Could not unlock pixel buffer");
        return;
    }

    cv_assert(CVPixelBufferUnlockBaseAddress(mPixelBuffer, 0),
              @"Could not unlock pixel buffer");
    cv_assert(CVOpenGLTextureCacheCreateTextureFromImage(NULL, textureCache, mPixelBuffer,
                                                         NULL, &mCVTexture),
              @"Could not create primitive texture");
}

- (void) updateData: (const render_primitive *) primitive
       textureCache: (CVOpenGLTextureCacheRef) textureCache;
{
    if (mPixelBuffer != NULL)
    {
        CVPixelBufferRelease(mPixelBuffer);
        CVOpenGLTextureRelease(mCVTexture);
        mPixelBuffer = NULL;
        mCVTexture = NULL;
    }

    flags = primitive->flags;
    texinfo.seqid = primitive->texture.seqid;
    [self setData: textureCache];
}

- (void) renderPrimitive: (const render_primitive * ) primitive
         centeringOffset: (NSSize) mCenteringOffset
            linearFilter: (BOOL) linearFilter;
{
    MameOpenGLTexture * texture = self;
    
    float du = ustop - ustart; 
    float dv = vstop - vstart;
    
    GLenum textureTarget = CVOpenGLTextureGetTarget(mCVTexture);
    glEnable(textureTarget);
    glBindTexture(CVOpenGLTextureGetTarget(mCVTexture),
                  CVOpenGLTextureGetName(mCVTexture));
    
    // non-screen textures will never be filtered
    if (PRIMFLAG_GET_SCREENTEX(flags) && linearFilter)
    {
        glTexParameteri(textureTarget, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(textureTarget, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    else
    {
        glTexParameteri(textureTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(textureTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }
    
    // texture rectangles can't wrap
    glTexParameteri(textureTarget, GL_TEXTURE_WRAP_S, GL_CLAMP);
    glTexParameteri(textureTarget, GL_TEXTURE_WRAP_T, GL_CLAMP);
    
    // texture coordinates for TEXTURE_RECTANGLE are 0,0 -> w,h
    // rather than 0,0 -> 1,1 as with normal OpenGL texturing
    du *= (float) rawwidth;
    dv *= (float) rawheight;
    
    GLfloat color[4];
    color[0] = primitive->color.r;
    color[1] = primitive->color.g;
    color[2] = primitive->color.b;
    color[3] = primitive->color.a;
    
    glBegin(GL_QUADS);
    glColor4fv(color);
    glTexCoord2f(ustart + du * primitive->texcoords.tl.u,
                 vstart + dv * primitive->texcoords.tl.v);
    glVertex2f(primitive->bounds.x0 + mCenteringOffset.width,
               primitive->bounds.y0 + mCenteringOffset.height);
    glColor4fv(color);
    glTexCoord2f(ustart + du * primitive->texcoords.tr.u,
                 vstart + dv * primitive->texcoords.tr.v);
    glVertex2f(primitive->bounds.x1 + mCenteringOffset.width,
               primitive->bounds.y0 + mCenteringOffset.height);
    glColor4fv(color);
    glTexCoord2f(ustart + du * primitive->texcoords.br.u,
                 vstart + dv * primitive->texcoords.br.v);
    glVertex2f(primitive->bounds.x1 + mCenteringOffset.width,
               primitive->bounds.y1 + mCenteringOffset.height);
    glColor4fv(color);
    glTexCoord2f(ustart + du * primitive->texcoords.bl.u,
                 vstart + dv * primitive->texcoords.bl.v);
    glVertex2f(primitive->bounds.x0 + mCenteringOffset.width,
               primitive->bounds.y1 + mCenteringOffset.height);
    glEnd();
    glDisable(textureTarget);
}

@end

@implementation MameOpenGLTexture (Private)


@end
