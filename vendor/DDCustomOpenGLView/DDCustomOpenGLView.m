/*
 * Copyright (c) 2006 Dave Dribin
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

#import "DDCustomOpenGLView.h"
#import "JRLog.h"

#define ANIMATE_WITH_DISPLAY_LINK 1

@interface DDCustomOpenGLView (Private)

- (void) initDisplayLink;
- (void) emptyThreadEntry;
- (void) surfaceNeedsUpdate: (NSNotification *) notification;
- (void) drawFrameAndFlush;
- (void) animationTimerFired;
- (BOOL) isDoubleBuffered: (NSOpenGLPixelFormat *) pixelFormat;
- (void) flushBuffer: (NSOpenGLContext *) context;
- (void) updateSyncToRefreshOnContext: (NSOpenGLContext *) context;

#pragma mark -
#pragma mark Full Screen

- (void) enterFullScreen;
- (void) exitFullScreen;
- (void) fullscreenEventLoop;
- (CGDisplayErr) switchToDisplayMode: (CGDirectDisplayID) display
                               width: (size_t) width 
                              height: (size_t) height
                         refreshRate: (CGRefreshRate) refreshRate;
- (CGDisplayFadeReservationToken) displayFadeOut;
- (void) displayFadeIn: (CGDisplayFadeReservationToken) token;

@end

@implementation DDCustomOpenGLView

+ (NSOpenGLPixelFormat *) defaultPixelFormat
{
    NSOpenGLPixelFormatAttribute attribs[] = {0};
    return [[(NSOpenGLPixelFormat *)[NSOpenGLPixelFormat alloc] initWithAttributes:attribs] autorelease];
}

- (id) initWithFrame: (NSRect) frame
{
    return [self initWithFrame: frame
                   pixelFormat: [[self class] defaultPixelFormat]];
}

- (id) initWithFrame: (NSRect) frame
         pixelFormat: (NSOpenGLPixelFormat *) pixelFormat;
{
    self = [super initWithFrame: frame];
    if (self == nil)
        return nil;
        
    mOpenGLContext = nil;
    mPixelFormat = [pixelFormat retain];
    
    mDoubleBuffered = [self isDoubleBuffered: mPixelFormat];

    mFullScreenOpenGLContext = nil;
    mFullScreenPixelFormat = nil;
    mFullScreen = NO;
    mFullScreenWidth = 800;
    mFullScreenHeight = 600;
    mFullScreenRefreshRate = 60.0;
    mFadeTime = 0.5f;
    mSwitchModesForFullScreen = YES;
    
    mOpenGLLock = [[NSRecursiveLock alloc] init];
    
    [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(surfaceNeedsUpdate:)
               name: NSViewGlobalFrameDidChangeNotification
             object: self];


    mDisplayLink = NULL;
    mAnimationTimer = nil;
#if ANIMATE_WITH_DISPLAY_LINK
    JRLogInfo(@"Animate with display link");
    [self initDisplayLink];
#else
    NSLog(@"Animate with timer");
#endif
    
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mOpenGLContext release];
    [mPixelFormat release];
    [mFullScreenOpenGLContext release];
    [mFullScreenPixelFormat release];
    [mOpenGLLock release];
    
    mOpenGLContext = nil;
    mPixelFormat = nil;
    mFullScreenOpenGLContext = nil;
    mFullScreenPixelFormat = nil;
    mOpenGLLock = nil;
    [super dealloc];
}

- (void) drawRect: (NSRect)rect
{
    [self lockOpenGLLock];
    NSOpenGLContext * currentContext = [self activeOpenGLContext];
    {
        [currentContext makeCurrentContext];
        [self drawFrame];
        // Don't flush the buffer here, as the window server does an implicit
        // swap, if necessary.
        // glFlush(); ???
        [self flushBuffer: currentContext];
    }
    [self unlockOpenGLLock];
}

//=========================================================== 
//  openGLContext 
//=========================================================== 
- (NSOpenGLContext *) openGLContext
{
    [self lockOpenGLLock];
    {
        if (mOpenGLContext == nil)
        {
            mOpenGLContext =
                [[NSOpenGLContext alloc] initWithFormat: mPixelFormat
                                           shareContext: nil];
            [mOpenGLContext makeCurrentContext];
            [self prepareOpenGL: mOpenGLContext];
            [self updateSyncToRefreshOnContext: mOpenGLContext];
        }
    }
    [self unlockOpenGLLock];
    return mOpenGLContext;
}

- (void) setOpenGLContext: (NSOpenGLContext *) anOpenGLContext
{
    [self lockOpenGLLock];
    {
        if (mOpenGLContext != anOpenGLContext)
        {
            [mOpenGLContext release];
            mOpenGLContext = [anOpenGLContext retain];
        }
    }
    [self unlockOpenGLLock];
}

//=========================================================== 
//  pixelFormat 
//=========================================================== 
- (NSOpenGLPixelFormat *) pixelFormat
{
    return mPixelFormat; 
}

- (void) setPixelFormat: (NSOpenGLPixelFormat *) aPixelFormat
{
    [self lockOpenGLLock];
    {
        if (mPixelFormat != aPixelFormat)
        {
            [mPixelFormat release];
            mPixelFormat = [aPixelFormat retain];
        }
    }
    [self unlockOpenGLLock];
}


- (void) prepareOpenGL: (NSOpenGLContext *) context;
{
    // for overriding to initialize OpenGL state, occurs after context creation
}

//=========================================================== 
//  syncToRefresh 
//=========================================================== 
- (BOOL) syncToRefresh
{
    return mSyncToRefresh;
}

- (void) setSyncToRefresh: (BOOL) flag
{
    [self lockOpenGLLock];
    {
        mSyncToRefresh = flag;
        // Only set it on the context, if we've been iniitialized
        if (mOpenGLContext != nil)
            [self updateSyncToRefreshOnContext: [self activeOpenGLContext]];
    }
    [self unlockOpenGLLock];
}

#pragma mark -
#pragma mark Active OpenGL Properties

- (NSOpenGLContext *) activeOpenGLContext;
{
    if (mFullScreen)
        return [self fullScreenOpenGLContext];
    else
        return [self openGLContext];
}

- (NSOpenGLPixelFormat *) activePixelFormat;
{
    if (mFullScreen)
        return [self fullScreenPixelFormat];
    else
        return [self pixelFormat];
}

- (NSRect) activeBounds;
{
    if (mFullScreen)
        return mFullScreenRect;
    else
        return [self bounds];
}

- (BOOL) isOpaque
{
    return YES;
}

- (void) lockFocus
{
    // make sure we are ready to draw
    [super lockFocus];
    
    [self lockOpenGLLock];
    if (!mFullScreen)
    {
        // get context. will create if we don't have one yet
        NSOpenGLContext* context = [self activeOpenGLContext];
        
        // when we are about to draw, make sure we are linked to the view
        if ([context view] != self)
        {
            [context setView: self];
        }
        
        // make us the current OpenGL context
        [context makeCurrentContext];
    }
    [self unlockOpenGLLock];
}

// no reshape will be called since NSView does not export a specific reshape method

- (void) update
{
    [self lockOpenGLLock];
    {
        NSOpenGLContext * context = [self activeOpenGLContext];
        
        if ([context view] == self)
        {
            [context update];
        }
    }
    [self unlockOpenGLLock];
}

- (void) lockOpenGLLock;
{
#if ANIMATE_WITH_DISPLAY_LINK
    [mOpenGLLock lock];
#endif
}

- (void) unlockOpenGLLock;
{
#if ANIMATE_WITH_DISPLAY_LINK
    [mOpenGLLock unlock];
#endif
}

#pragma mark -
#pragma mark Animation

- (void) startAnimation;
{
#if ANIMATE_WITH_DISPLAY_LINK
    CVDisplayLinkStart(mDisplayLink);
#else
    mAnimationTimer =
        [NSTimer scheduledTimerWithTimeInterval: 1.0f/60.0f
                                         target: self
                                       selector: @selector(animationTimerFired)
                                       userInfo: nil
                                        repeats: YES];
    [mAnimationTimer retain];
#endif    
}

- (void) stopAnimation;
{
#if ANIMATE_WITH_DISPLAY_LINK
    CVDisplayLinkStop(mDisplayLink);
#else
    [mAnimationTimer invalidate];
    [mAnimationTimer release];
    mAnimationTimer = nil;
#endif
}

- (BOOL) isAnimationRunning;
{
#if ANIMATE_WITH_DISPLAY_LINK
    return CVDisplayLinkIsRunning(mDisplayLink);
#else
    return (mAnimationTimer != nil);
#endif
}


- (void) updateAnimation;
{
}

- (void) drawFrame;
{
}

#pragma mark -
#pragma mark Full Screen

//=========================================================== 
//  fullScreenOpenGLContext 
//=========================================================== 
- (NSOpenGLContext *) fullScreenOpenGLContext
{
    [self lockOpenGLLock];
    {
        if ((mFullScreenOpenGLContext == nil) && (mFullScreenPixelFormat != nil))
        {
            mFullScreenOpenGLContext =
                [[NSOpenGLContext alloc] initWithFormat: mFullScreenPixelFormat
                                           shareContext: [self openGLContext]];
            [mFullScreenOpenGLContext makeCurrentContext];
            [self prepareOpenGL: mFullScreenOpenGLContext];
            [self updateSyncToRefreshOnContext: mFullScreenOpenGLContext];
        }
    }
    [self unlockOpenGLLock];
    return mFullScreenOpenGLContext; 
}

- (void) setFullScreenOpenGLContext: (NSOpenGLContext *) aFullScreenOpenGLContext
{
    [self lockOpenGLLock];
    {
        if (mFullScreenOpenGLContext != aFullScreenOpenGLContext)
        {
            [mFullScreenOpenGLContext release];
            mFullScreenOpenGLContext = [aFullScreenOpenGLContext retain];
        }
    }
    [self unlockOpenGLLock];
}

//=========================================================== 
//  fullScreenPixelFormat 
//=========================================================== 
- (NSOpenGLPixelFormat *) fullScreenPixelFormat
{
    return mFullScreenPixelFormat; 
}

- (void) setFullScreenPixelFormat: (NSOpenGLPixelFormat *) aFullScreenPixelFormat
{
    [self lockOpenGLLock];
    {
        if (mFullScreenPixelFormat != aFullScreenPixelFormat)
        {
            [mFullScreenPixelFormat release];
            mFullScreenPixelFormat = [aFullScreenPixelFormat retain];
        }
    }
    [self unlockOpenGLLock];
}

- (void) setFullScreenWidth: (int) width height: (int) height;
{
    mFullScreenWidth = width;
    mFullScreenHeight = height;
}

- (int) fullScreenWidth;
{
    return mFullScreenWidth;
}

- (int) fullScreenHeight;
{
    return mFullScreenHeight;
}

- (void) setFullScreenRefreshRate: (double) fullScreenRefreshRate;
{
    mFullScreenRefreshRate = fullScreenRefreshRate;
}

- (double) fullScreenRefreshRate;
{
    return mFullScreenRefreshRate;
}

- (void) setFadeTime: (float) fadeTime;
{
    mFadeTime = fadeTime;
}

- (float) fadeTime;
{
    return mFadeTime;
}

//=========================================================== 
//  switchModesForFullScreen 
//=========================================================== 
- (BOOL) switchModesForFullScreen
{
    return mSwitchModesForFullScreen;
}

- (void) setSwitchModesForFullScreen: (BOOL) flag
{
    mSwitchModesForFullScreen = flag;
}

//=========================================================== 
//  fullScreen 
//=========================================================== 
- (BOOL) fullScreen
{
    return mFullScreen;
}

- (void) setFullScreen: (BOOL) fullScreen
{
    if (fullScreen && !mFullScreen)
    {
        if ([self fullScreenOpenGLContext] != nil)
        {
            [self enterFullScreen];
            mFullScreen = YES;
        }
    }
    else if (!fullScreen && mFullScreen)
    {
        [self exitFullScreen];
        mFullScreen = NO;
    }
}

- (void) willEnterFullScreen;
{
}

- (void) willExitFullScreen;
{
}

- (void) didEnterFullScreen: (NSSize) fullScreenSize;
{
}

- (void) didExitFullScreen;
{
}


- (CFDictionaryRef) findBestDisplayMode: (CGDirectDisplayID) display
                                  width: (size_t) width 
                                 height: (size_t) height
                            refreshRate: (CGRefreshRate) refreshRate;
{
    return CGDisplayBestModeForParametersAndRefreshRateWithProperty(
        display,
        CGDisplayBitsPerPixel(display),     
        width,                              
        height,                             
        refreshRate,                                
        kCGDisplayModeIsSafeForHardware,
        NULL);
}

@end

#pragma mark -

@implementation DDCustomOpenGLView (Private)

CVReturn static myCVDisplayLinkOutputCallback(CVDisplayLinkRef displayLink, 
                                              const CVTimeStamp *inNow, 
                                              const CVTimeStamp *inOutputTime, 
                                              CVOptionFlags flagsIn, 
                                              CVOptionFlags *flagsOut, 
                                              void *displayLinkContext)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    DDCustomOpenGLView * view = (DDCustomOpenGLView *) displayLinkContext;
    [view animationTimerFired];
    [pool release];
    return kCVReturnSuccess;
}

- (void) initDisplayLink;
{
    // Detaching a thread forces [NSThread isMultiThreaded] to return YES.
    // http://developer.apple.com/documentation/Cocoa/Conceptual/Multithreading/articles/CocoaDetaching.html
    [NSThread detachNewThreadSelector: @selector(emptyThreadEntry)
                             toTarget: self
                           withObject: nil];
    
    CVReturn error = kCVReturnSuccess;
    CGDirectDisplayID displayID = CGMainDisplayID();
    
    error = CVDisplayLinkCreateWithCGDisplay(displayID, &mDisplayLink);
    if(error)
    {
        NSLog(@"DisplayLink created with error:%d", error);
        mDisplayLink = NULL;
        return;
    }
    error = CVDisplayLinkSetOutputCallback(mDisplayLink,
                                           myCVDisplayLinkOutputCallback, self);
}

- (void) animationTimerFired;
{
    [self updateAnimation];
    [self drawFrameAndFlush];
}

- (void) emptyThreadEntry;
{
    // Exit right away.
}

- (void) surfaceNeedsUpdate: (NSNotification *) notification;
{
    [self update];
}

- (void) drawFrameAndFlush;
{
    NSOpenGLContext * currentContext = [self activeOpenGLContext];
    
    [self lockOpenGLLock];
    {
        [currentContext makeCurrentContext];
        [self drawFrame];
        [self flushBuffer: [self activeOpenGLContext]];
    }
    [self unlockOpenGLLock];
}

- (BOOL) isDoubleBuffered: (NSOpenGLPixelFormat *) pixelFormat;
{
    int value;
    [pixelFormat getValues: &value
              forAttribute: NSOpenGLPFADoubleBuffer
          forVirtualScreen: 0];
    return value == 1? YES : NO;
}

- (void) flushBuffer: (NSOpenGLContext *) context;
{
    if (mDoubleBuffered)
        [context flushBuffer];
    else
        glFlush();
}

#pragma mark -
#pragma mark Full Screen

- (void) enterFullScreen;
{
    [self willEnterFullScreen];
    BOOL isAnimationRunning = [self isAnimationRunning];
    if (isAnimationRunning)
        [self stopAnimation];
    CGDisplayFadeReservationToken token = [self displayFadeOut];

    [self lockOpenGLLock];
    {
        
        // clear the current context (window)
        NSOpenGLContext *windowContext = [self openGLContext];
        [windowContext makeCurrentContext];
        glClear(GL_COLOR_BUFFER_BIT);
        [self flushBuffer: windowContext];
        [windowContext clearDrawable];
        
        // ask to black out all the attached displays
        CGCaptureAllDisplays();
        // hide the cursor
        CGDisplayHideCursor(kCGDirectMainDisplay);
        // Remove the menu bar, so it doesn't register mouse clicks
        [NSMenu setMenuBarVisible: NO];
        
        float oldHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
        
        // change the display device resolution
        if (mSwitchModesForFullScreen)
        {
            [self switchToDisplayMode: kCGDirectMainDisplay
                                width: mFullScreenWidth
                               height: mFullScreenHeight
                          refreshRate: mFullScreenRefreshRate];
        }
        
        // find out the new device bounds
        mFullScreenRect.origin.x = 0; 
        mFullScreenRect.origin.y = 0; 
        mFullScreenRect.size.width = CGDisplayPixelsWide(kCGDirectMainDisplay); 
        mFullScreenRect.size.height = CGDisplayPixelsHigh(kCGDirectMainDisplay);
        
        // account for a workaround for fullscreen mode in AppKit
        // <http://www.idevgames.com/forum/showthread.php?s=&threadid=1461&highlight=mouse+location+cocoa>
        mFullScreenMouseOffset = oldHeight - mFullScreenRect.size.height + 1;
        
        // activate the fullscreen context and clear it
        mDoubleBuffered = [self isDoubleBuffered: mFullScreenPixelFormat];

        [mFullScreenOpenGLContext makeCurrentContext];
        [self updateSyncToRefreshOnContext: mFullScreenOpenGLContext];
        glClear(GL_COLOR_BUFFER_BIT);
        [self flushBuffer: mFullScreenOpenGLContext];
        [mFullScreenOpenGLContext setFullScreen];
        
        [self update];
    }
    [self unlockOpenGLLock];
    
    [self displayFadeIn: token];    
    [self didEnterFullScreen: mFullScreenRect.size];
    if (isAnimationRunning)
        [self startAnimation];
    
    // enter the manual event loop processing
    [self fullscreenEventLoop];
}

- (void) exitFullScreen;
{
    [self willExitFullScreen];
    BOOL isAnimationRunning = [self isAnimationRunning];
    if (isAnimationRunning)
        [self stopAnimation];
    CGDisplayFadeReservationToken token = [self displayFadeOut];
    
    [self lockOpenGLLock];
    {
        
        // clear the current context (fullscreen)
        [mFullScreenOpenGLContext makeCurrentContext];
        glClear(GL_COLOR_BUFFER_BIT);
        [self flushBuffer: mFullScreenOpenGLContext];
        [mFullScreenOpenGLContext clearDrawable];
        
        // Bring the menu bar back
        [NSMenu setMenuBarVisible: YES];
        // show the cursor
        CGDisplayShowCursor(kCGDirectMainDisplay);
        // ask the attached displays to return to normal operation
        CGReleaseAllDisplays();
        
        // activate the window context and clear it
        NSOpenGLContext * windowContext = [self openGLContext];
        mDoubleBuffered = [self isDoubleBuffered: mPixelFormat];
        if ([[self window] isVisible])
            [windowContext setView: self];
        
        [windowContext makeCurrentContext];
        [self updateSyncToRefreshOnContext: windowContext];
        glClear(GL_COLOR_BUFFER_BIT);
        [self flushBuffer: windowContext];
        
        [self update];
    }
    [self unlockOpenGLLock];
    
    [self displayFadeIn: token];
    [self didExitFullScreen];
    if (isAnimationRunning)
        [self startAnimation];
}

- (void) fullscreenEventLoop;
{
    while (mFullScreen)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // check for and process input events.
        NSDate * expiration = [NSDate distantPast];
        NSEvent * event = [NSApp nextEventMatchingMask: NSAnyEventMask
                                             untilDate: expiration
                                                inMode: NSDefaultRunLoopMode
                                               dequeue: YES];
        if (event != nil)
            [NSApp sendEvent: event];
        [pool release];
    }
}

- (CGDisplayErr) switchToDisplayMode: (CGDirectDisplayID) display
                               width: (size_t) width 
                              height: (size_t) height
                         refreshRate: (CGRefreshRate) refreshRate;
{
    CFDictionaryRef displayMode =
        [self findBestDisplayMode: display
                            width: width
                           height: height
                      refreshRate: refreshRate];
    return CGDisplaySwitchToMode(display, displayMode);
}

- (CGDisplayFadeReservationToken) displayFadeOut;
{
    CGDisplayFadeReservationToken token;
    CGDisplayErr err =
        CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &token); 
    if (err == CGDisplayNoErr)
    {
        CGDisplayFade(token, mFadeTime, kCGDisplayBlendNormal,
                      kCGDisplayBlendSolidColor, 0, 0, 0, true); 
    }
    else
    { 
        token = kCGDisplayFadeReservationInvalidToken;
    }
    
    return token;
}

- (void) displayFadeIn: (CGDisplayFadeReservationToken) token;
{
    if (token != kCGDisplayFadeReservationInvalidToken)
    {
        CGDisplayFade(token, mFadeTime, kCGDisplayBlendSolidColor,
                      kCGDisplayBlendNormal, 0, 0, 0, true); 
        CGReleaseDisplayFadeReservation(token); 
    }
}

- (void) updateSyncToRefreshOnContext: (NSOpenGLContext *) context;
{
    int swapInterval = mSyncToRefresh? 1 : 0;
    [context setValues: &swapInterval forParameter: NSOpenGLCPSwapInterval];
}

@end
