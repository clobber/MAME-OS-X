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

#import "MameOpenGLRenderer.h"
#import "MameTextureTable.h"
#import "MameOpenGLTexture.h"

@interface MameOpenGLRenderer (Private)

- (void) renderLine: (render_primitive *) primitive;
- (void) renderQuad: (render_primitive *) primitive;

@end

@implementation MameOpenGLRenderer

- (id) init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mLinearFilter = YES;
    mTextureTable =  nil;
    mGlContext = nil;
    
    return self;
}

- (void) dealloc;
{
    [self osd_exit];
    [super dealloc];
}

- (void) osd_init: (NSOpenGLContext *) mameViewContext
           format: (NSOpenGLPixelFormat *) mameViewFormat;
{
    NSOpenGLPixelFormat * glPixelFormat = mameViewFormat;
    mGlContext = [mameViewContext retain];
   
    mTextureTable = [[MameTextureTable alloc] initWithContext: mGlContext 
                                                  pixelFormat: glPixelFormat];
}

- (void) osd_exit;
{
    [mTextureTable release];
    mTextureTable =  nil;
    
    [mGlContext release];
    mGlContext = nil;
}

- (BOOL) linearFilter;
{
    return mLinearFilter;
}

- (void) setLinearFilter: (BOOL) linearFilter;
{
    mLinearFilter = linearFilter;
}

INLINE void set_blendmode(int blendmode)
{
    switch (blendmode)
    {
        case BLENDMODE_NONE:
            glDisable(GL_BLEND);
            break;
        case BLENDMODE_ALPHA:       
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            break;
        case BLENDMODE_RGB_MULTIPLY:    
            glEnable(GL_BLEND);
            glBlendFunc(GL_DST_COLOR, GL_ZERO);
            break;
        case BLENDMODE_ADD:     
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            break;
    }
}

- (void) renderFrame: (const render_primitive_list *) primlist
            withSize: (NSSize) size;
{
    // clear the screen and Z-buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // reset the current matrix to the identity
    glLoadIdentity();                                  
    
    // we're doing nothing 3d, so the Z-buffer is currently not interesting
    glDisable(GL_DEPTH_TEST);
    
    glDisable(GL_LINE_SMOOTH);
    glDisable(GL_POINT_SMOOTH);
    
    // enable blending
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // set lines and points just barely above normal size to get proper results
    glLineWidth(1.1f);
    glPointSize(1.1f);
    
    // set up a nice simple 2D coordinate system, so GL behaves exactly how we'd like.
    //
    // (0,0)     (w,0)
    //   |~~~~~~~~~|
    //   |         |
    //   |         |
    //   |         |
    //   |_________|
    // (0,h)     (w,h)
    
    glViewport(0.0, 0.0, (GLsizei)size.width, (GLsizei)size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, (GLdouble)size.width, (GLdouble)size.height, 0.0, 0.0, -1.0);
    
    // compute centering parameters
    mCenteringOffset = NSMakeSize(0.0f, 0.0f);
    
    // first update/upload the textures
    [mTextureTable performHousekeeping];
    
    render_primitive * prim;
    //for (prim = primlist->head; prim != NULL; prim = prim->next)
    for (prim = primlist->first(); prim != NULL; prim = prim->next())
    {
        if (prim->texture.base != NULL)
        {
            [mTextureTable updateTextureForPrimitive: prim];
        }
    }
    
    // now draw
    //for (prim = primlist->head; prim != NULL; prim = prim->next)
    for (prim = primlist->first(); prim != NULL; prim = prim->next())
    {
        set_blendmode(PRIMFLAG_GET_BLENDMODE(prim->flags));
        switch (prim->type)
        {
            case render_primitive::LINE:
                [self renderLine: prim];
                break;
                
            case render_primitive::QUAD:
            {
                MameOpenGLTexture * texture = [mTextureTable findTextureForPrimitive: prim];
                if (texture == nil)
                    [self renderQuad: prim];
                else
                {
                    [texture renderPrimitive: prim
                             centeringOffset: mCenteringOffset
                                linearFilter: mLinearFilter];
                }
            }
                break;
        }
    }
}

@end

@implementation MameOpenGLRenderer (Private)

- (void) renderLine: (render_primitive *) prim;
{    
    GLfloat color[4];
    color[0] = prim->color.r;
    color[1] = prim->color.g;
    color[2] = prim->color.b;
    color[3] = prim->color.a;

    // check if it's really a point
    if (((prim->bounds.x1 - prim->bounds.x0) == 0) &&
        ((prim->bounds.y1 - prim->bounds.y0) == 0))
    {
        glBegin(GL_POINTS);
        glColor4fv(color);
        glVertex2f(prim->bounds.x0 + mCenteringOffset.width,
                   prim->bounds.y0 + mCenteringOffset.height);
        glEnd();
    }
    else
    {
        glBegin(GL_LINES);
        glColor4fv(color);
        glVertex2f(prim->bounds.x0 + mCenteringOffset.width,
                   prim->bounds.y0 + mCenteringOffset.height);
        glVertex2f(prim->bounds.x1 + mCenteringOffset.width,
                   prim->bounds.y1 + mCenteringOffset.height);
        glEnd();
    }
}

- (void) renderQuad: (render_primitive *) prim;
{
    GLfloat color[4];
    color[0] = prim->color.r;
    color[1] = prim->color.g;
    color[2] = prim->color.b;
    color[3] = prim->color.a;

    glBegin(GL_QUADS);
    glColor4fv(color);
    glVertex2f(prim->bounds.x0 + mCenteringOffset.width,
               prim->bounds.y0 + mCenteringOffset.height);
    glColor4fv(color);
    glVertex2f(prim->bounds.x1 + mCenteringOffset.width,
               prim->bounds.y0 + mCenteringOffset.height);
    glColor4fv(color);
    glVertex2f(prim->bounds.x1 + mCenteringOffset.width,
               prim->bounds.y1 + mCenteringOffset.height);
    glColor4fv(color);
    glVertex2f(prim->bounds.x0 + mCenteringOffset.width,
               prim->bounds.y1 + mCenteringOffset.height);
    glEnd();
}

@end
