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

#import "MameView.h"
#import "MameController.h"
#import "MameRenderer.h"
#import "MameInputController.h"
#import "MameAudioController.h"
#import "MameTimingController.h"
#import "MameFileManager.h"
#import "MameConfiguration.h"
#import "MameFilter.h"
#import "JRLog.h"
#import "MameChud.h"
#import "MameEffectFilter.h"
#import <Quartz/Quartz.h>
#import <mach/mach_host.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import "osd_osx.h"

#define MAME_EXPORT_MOVIE 0

#if MAME_EXPORT_MOVIE
#import <QuickTime/QuickTime.h>
#import "exporter/FrameReader.h"
#import "exporter/FrameCompressor.h"
#import "exporter/FrameMovieExporter.h"
#endif

@interface MameView (Private)

- (BOOL) isCoreImageAccelerated;
- (BOOL) hasMultipleCPUs;

- (void) gameThread;
- (void) gameFinished: (NSNumber *) exitStatus;

- (void) updateMouseCursor;
- (void) hideMouseCursor;
- (void) showMouseCursor;

#pragma mark -
#pragma mark "Notifications and Delegates"

- (void) sendMameWillStartGame;
- (void) sendMameDidFinishGame;

- (NSString *) formatOutputMessage: (const char *) utf8Format
                         arguments: (va_list) argptr;

#pragma mark -
#pragma mark "Frame Drawing"

- (void) drawFrame;
- (void) drawFrameUsingCoreImage: (CVOpenGLTextureRef) frame
                          inRect: (NSRect) destRect;

- (QCRenderer *) activeQCRenderer;
- (void) drawFrameUsingQCRenderer: (CVOpenGLTextureRef) frame
                           inRect: (NSRect) destRect;

- (void) drawFrameUsingOpenGL: (CVOpenGLTextureRef) frame
                       inRect: (NSRect) destRect;
- (void) updateVideo;

- (NSRect) centerNSSize: (NSSize) size withinRect: (NSRect) rect;

- (void) updateDisplayProperties;
- (void) setPropertiesWithDisplay: (CGDirectDisplayID) displayId;

#if MAME_EXPORT_MOVIE
- (void) createMovieExporter;
- (void) exportMovieFrame;
- (void) freeMovieExporter;
#endif

@end

NSString * MameWillStartGame = @"MameWillStartGame";
NSString * MameDidFinishGame = @"MameDidFinishGame";
NSString * MameExitStatusKey = @"MameExitStatus";

@implementation MameView

+ (void) initialize
{
    [self setKeys: [NSArray arrayWithObject: @"indexOfCurrentEffect"]
          triggerChangeNotificationsForDependentKey: @"audioEffectFactoryPresets"];
    [self setKeys: [NSArray arrayWithObject: @"indexOfCurrentEffect"]
          triggerChangeNotificationsForDependentKey: @"indexOfCurrentFactoryPreset"];
    // Ensure our custom filter registers with the system
    [MameEffectFilter class];
}

- (id) initWithFrame: (NSRect) frameRect
{
    // pixel format attributes for the view based (non-fullscreen) NSOpenGLContext
    NSOpenGLPixelFormatAttribute windowedAttributes[] =
    {
        // specifying "NoRecovery" gives us a context that cannot fall back to the software renderer
        // this makes the view-based context a compatible with the fullscreen context,
        // enabling us to use the "shareContext" feature to share textures, display lists, and other OpenGL objects between the two
        NSOpenGLPFANoRecovery,
        // attributes common to fullscreen and window modes
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        0
    };
    NSOpenGLPixelFormat * windowedPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: windowedAttributes];
    [windowedPixelFormat autorelease];
    
    self = [super initWithFrame: frameRect pixelFormat: windowedPixelFormat];
    if (self == nil)
        return nil;
    
    // pixel format attributes for the full screen NSOpenGLContext
    NSOpenGLPixelFormatAttribute fullScreenAttributes[] =
    {
        // specify that we want a fullscreen OpenGL context
        NSOpenGLPFAFullScreen,
        // we may be on a multi-display system (and each screen may be driven
        // by a different renderer), so we need to specify which screen we want
        // to take over. 
        // in this case, we'll specify the main screen.
        NSOpenGLPFAScreenMask, CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay),
        // attributes common to fullscreen and window modes
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        0
    };
    NSOpenGLPixelFormat * fullScreenPixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: fullScreenAttributes];
    [fullScreenPixelFormat autorelease];
    [self setFullScreenPixelFormat: fullScreenPixelFormat];
    [self setFadeTime: 0.25f];
    
    mKeepAspectRatio = YES;
    mClearToRed = NO;
    [self setFrameRenderingOption: [self frameRenderingOptionDefault]];
    [self setRenderInCoreVideoThread: [self renderInCoreVideoThreadDefault]];
    [self setFullScreenZoom: MameFullScreenMaximum];
    
    mRenderer = [[MameRenderer alloc] init];
    mInputController = [[MameInputController alloc] init];
    mAudioController = [[MameAudioController alloc] init];
    mTimingController = [[MameTimingController alloc] init];
    mFileManager = [[MameFileManager alloc] init];
    
    [mTimingController addObserver: self
                        forKeyPath: @"throttled"
                           options: 0
                           context: nil];
    return self;
}

- (void) awakeFromNib
{
    [self setGame: nil];

    osx_osd_set_use_autorelease(NO);
    // osd_set_controller(self);
    osd_set_controller(self);
    osd_set_input_controller(mInputController);
    osd_set_audio_controller(mAudioController);
    osd_set_timing_controller(mTimingController);
    osd_set_file_manager(mFileManager);

    mSyncToRefresh = NO;
    mMameLock = [[NSLock alloc] init];
    mMameIsRunning = NO;
    mMameIsPaused = NO;
    mMouseCursorIsHidden = NO;
}

- (void) dealloc
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    
    if (mDelegate != nil)
        [center removeObserver: mDelegate name: nil object: self];
    
    [super dealloc];
}

- (void) prepareOpenGL;
{
    glShadeModel(GL_SMOOTH);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
}

- (void) prepareOpenGL: (NSOpenGLContext *) context;
{
    int swapInterval;
    swapInterval = 1;
    
    [context setValues: &swapInterval
                       forParameter: NSOpenGLCPSwapInterval];

    glShadeModel(GL_SMOOTH);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClearDepth(1.0f);
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
}

- (void) createCIContext;
{
    [[self openGLContext] makeCurrentContext];
    /* Create CGColorSpaceRef */
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    /* Create CIContext */
    mWindowedCiContext = [[CIContext contextWithCGLContext:
        (CGLContextObj)[[self openGLContext] CGLContextObj]
                                       pixelFormat:(CGLPixelFormatObj)
        [[self pixelFormat] CGLPixelFormatObj]
                                           options:[NSDictionary dictionaryWithObjectsAndKeys:
                                               (id)colorSpace,kCIContextOutputColorSpace,
                                               (id)colorSpace,kCIContextWorkingColorSpace,nil]] retain];

    mFullScreenCiContext = [[CIContext contextWithCGLContext:
        (CGLContextObj)[[self fullScreenOpenGLContext] CGLContextObj]
                                       pixelFormat:(CGLPixelFormatObj)
        [[self fullScreenPixelFormat] CGLPixelFormatObj]
                                           options:[NSDictionary dictionaryWithObjectsAndKeys:
                                               (id)colorSpace,kCIContextOutputColorSpace,
                                               (id)colorSpace,kCIContextWorkingColorSpace,nil]] retain];
    
    CGColorSpaceRelease(colorSpace);
}

- (CIContext *) ciContext;
{
    if ([self fullScreen])
        return mFullScreenCiContext;
    else
        return mWindowedCiContext;
}

- (MameFrameRenderingOption) frameRenderingOption;
{
    return mFrameRenderingOption;
}

- (void) setFrameRenderingOption:
    (MameFrameRenderingOption) frameRenderingOption;
{
    mFrameRenderingOption = frameRenderingOption;
}

- (MameFrameRenderingOption) frameRenderingOptionDefault;
{
    if ([self isCoreImageAccelerated])
        return MameRenderFrameInQCComposition;
    else
        return MameRenderFrameInOpenGL;
}

//=========================================================== 
//  renderInCoreVideoThread 
//=========================================================== 
- (BOOL) renderInCoreVideoThread
{
    return mRenderInCoreVideoThread;
}

- (void) setRenderInCoreVideoThread: (BOOL) flag
{
#if 0  // Until triple buffering?
    mRenderInCoreVideoThread = flag;
#else
    mRenderInCoreVideoThread = NO;
#endif
}

- (BOOL) renderInCoreVideoThreadDefault;
{
    if ([self hasMultipleCPUs])
        return YES;
    else
        return NO;
}

//=========================================================== 
//  clearToRed 
//=========================================================== 
- (BOOL) clearToRed;
{
    return mClearToRed;
}

- (void) setClearToRed: (BOOL) clearToRed;
{
    mClearToRed = clearToRed;
}

#pragma mark -
#pragma mark Sizing

- (NSSize) naturalSize;
{
    return mNaturalSize;
}

- (NSSize) optimalSize;
{
    return mOptimalSize;
}

- (BOOL) keepAspectRatio;
{
    return mKeepAspectRatio;
}

- (void) setKeepAspectRatio: (BOOL) keepAspectRatio;
{
    mKeepAspectRatio = keepAspectRatio;
}

- (NSSize) stretchedSize: (NSSize) boundingSize;
{
    float aspectRatio = mNaturalSize.width/mNaturalSize.height; 
    float boundingAspectRatio = boundingSize.width/boundingSize.height;
    
    NSSize size;
    if (boundingAspectRatio > aspectRatio)
    {
        size.width = roundf(boundingSize.height*aspectRatio);
        size.height = boundingSize.height;
    }
    else
    {
        size.width = boundingSize.width;
        size.height = roundf(boundingSize.width/aspectRatio);
    }
    return size;
}

- (NSSize) integralStretchedSize: (NSSize) boundingSize;
{
    NSSize size = [self stretchedSize: boundingSize];
    
    size.height = floorf(size.height/mNaturalSize.height)*mNaturalSize.height;
    size.width = floorf(size.width/mNaturalSize.width)*mNaturalSize.width;
    return size;
}

- (NSSize) independentIntegralStretchedSize: (NSSize) boundingSize;
{
    // Fully stretch in both directions
    NSSize size = boundingSize;
    // Round to nearest integral multiple
    size.height = floorf(size.height/mNaturalSize.height)*mNaturalSize.height;
    size.width = floorf(size.width/mNaturalSize.width)*mNaturalSize.width;
    return size;
}

- (MameFullScreenZoom) fullScreenZoom;
{
    return mFullScreenZoom;
}

- (void) setFullScreenZoom: (MameFullScreenZoom) fullScreenZoom;
{
    mFullScreenZoom = fullScreenZoom;
}

- (CFDictionaryRef) findBestDisplayMode: (CGDirectDisplayID) display
                                  width: (size_t) width 
                                 height: (size_t) height
                            refreshRate: (CGRefreshRate) refreshRate;
{
    CFDictionaryRef bestMode = 0;
    JRLogDebug(@"Find best mode for: %dx%d@%.3f",
               width, height, refreshRate);

    int bitDepth = CGDisplayBitsPerPixel(display);
    float bestScore = 0.0;
    CFArrayRef modeList = CGDisplayAvailableModes(display);
    CFIndex count = CFArrayGetCount(modeList);
    CFIndex index;
    for (index = 0; index < count; index++)
    {
        CFDictionaryRef mode = (CFDictionaryRef)CFArrayGetValueAtIndex(modeList, index);
        NSNumber * number = (NSNumber *)
            CFDictionaryGetValue(mode, kCGDisplayBitsPerPixel);
        int modeBitDepth = [number intValue];
        
        if (modeBitDepth != bitDepth)
            continue;
        
        number = (NSNumber *)
            CFDictionaryGetValue(mode, kCGDisplayModeIsSafeForHardware);
        BOOL isSafeForHardware = [number boolValue];
        if (!isSafeForHardware)
            continue;
       
        number = (NSNumber *) CFDictionaryGetValue(mode, kCGDisplayWidth);
        size_t modeWidth = [number intValue];
        number = (NSNumber *) CFDictionaryGetValue(mode, kCGDisplayHeight);
        size_t modeHeight = [number intValue];

        // compute initial score based on difference between target and current
        float sizeScore = 1.0f /
            (1.0f + fabs(modeWidth - width) + fabs(modeHeight - height));
        
        // if the mode is too small, give a big penalty
        if (modeWidth < mNaturalSize.width || modeHeight < mNaturalSize.height)
            sizeScore *= 0.01f;
        
        // if mode is smaller than we'd like, it only scores up to 0.1
        if (modeWidth < width || modeHeight < height)
            sizeScore *= 0.1f;
        
        // A multiple of either height or width is the third best choice
        if (((modeWidth % width) == 0) || ((modeHeight % height) == 0))
            sizeScore = 0.5f;

        // A multiple height *and* width is the second best choice
        if (((modeWidth % width) == 0) && ((modeHeight % height) == 0))
            sizeScore = 1.0f;
       
        // An exact match, is the best
        if (modeWidth == width && modeHeight == height)
            sizeScore = 2.0f;
        
        number = (NSNumber *) CFDictionaryGetValue(mode, kCGDisplayRefreshRate);
        float modeRefreshRate = [number floatValue];

        // compute refresh score
        float refreshScore = 1.0f / (1.0f + fabs(modeRefreshRate - refreshRate));
        
        // if refresh is smaller than we'd like, it only scores up to 0.1
        if (modeRefreshRate < refreshRate)
            refreshScore *= 0.1;
        
        // if we're looking for a particular refresh, make sure it matches
        if (modeRefreshRate == refreshRate)
            refreshScore = 2.0f;
       
        number = (NSNumber *)
            CFDictionaryGetValue(mode, kCGDisplayModeIsStretched);
        BOOL isStretched = [number boolValue];
        float stretchedScore = isStretched? 0.1f : 2.0f;
        
        float finalScore = sizeScore + refreshScore + stretchedScore;
        BOOL foundBest = finalScore > bestScore;
        
        JRLogDebug(@"Mode: %4dx%4d@%7.3f%s = %f + %f + %f = %f > %f",
                   modeWidth, modeHeight, modeRefreshRate,
                   (isStretched? " (S)" : "    "), 
                   sizeScore, refreshScore, stretchedScore, finalScore,
                   bestScore);
        
        if (foundBest)
        {
            bestScore = finalScore;
            bestMode = mode;
        }

    }
   
    JRLogInfo(@"Best display mode: %@", (NSDictionary *) bestMode);
    return bestMode;
}

#pragma mark -

- (int) osd_init: (running_machine *) machine;
{
    JRLogInfo(@"osd_init");
    
    mMachine = machine;
    [mInputController osd_init: machine];
    [mAudioController osd_init: machine];
    [mTimingController osd_init: machine];
    
    //mTarget = render_target_alloc(machine, NULL, FALSE);
    mTarget = machine->render().target_alloc();
    
    //render_target_set_orientation(mTarget, ROT0);
    //render_target_set_layer_config(mTarget, LAYER_CONFIG_DEFAULT);
    //render_target_set_view(mTarget, 0);
    mTarget->set_orientation(ROT0);
    mTarget->layer_config();
    mTarget->set_view(0);

    INT32 minimumWidth;
    INT32 minimumHeight;
    //render_target_get_minimum_size(mTarget, &minimumWidth, &minimumHeight);
    mTarget->compute_minimum_size(minimumWidth, minimumHeight);
    [self updateDisplayProperties];
    INT32 visibleWidth, visibleHeight;
    //render_target_compute_visible_area
    mTarget->compute_visible_area(minimumWidth, minimumHeight,
                                       mPixelAspectRatio, ROT0,
                                       visibleWidth, visibleHeight);
    JRLogInfo(@"Aspect ratio: %f, Minimum size: %dx%d, visible size: %dx%d",
              mPixelAspectRatio, minimumWidth, minimumHeight, visibleWidth,
              visibleHeight);
    mNaturalSize = NSMakeSize(visibleWidth, visibleHeight);
    
    mOptimalSize = mNaturalSize;
    if ((mOptimalSize.width < 640) && (mOptimalSize.height < 480))
    {
        mOptimalSize.width *=2;
        mOptimalSize.height *= 2;
    }
    
    //const device_config * primaryScreen = video_screen_first(mMachine->config);
    const device_config * primaryScreen = screen_first(*mMachine->config);
    double targetRefresh = 60.0;
    // determine the refresh rate of the primary screen
    const screen_device_config *primary_screen = screen_first(*machine->config);
    if (primaryScreen != NULL)
    {
        //const screen_config * config = (const screen_config*)primaryScreen->inline_config;
        //targetRefresh = ATTOSECONDS_TO_HZ(config->refresh);
        targetRefresh = ATTOSECONDS_TO_HZ(primary_screen->refresh());
    }
    JRLogInfo(@"Target refresh: %.3f", targetRefresh);
    
    [self setFullScreenWidth: mNaturalSize.width height: mNaturalSize.height];
    [self setFullScreenRefreshRate: targetRefresh];

    [mMameLock unlock];
    [self performSelectorOnMainThread: @selector(sendMameWillStartGame)
                           withObject: nil
                        waitUntilDone: YES];
    [mMameLock lock];
        
    [self createCIContext];
    
    NSString * frameRendering;
    switch (mFrameRenderingOption)
    {
        case MameRenderFrameInOpenGL:
            frameRendering = @"OpenGL";
            break;
            
        case MameRenderFrameInCoreImage:
            frameRendering = @"Core Image";
            break;
            
        case MameRenderFrameInQCComposition:
            frameRendering = @"Quartz Composer Composition";
            break;
            
        default:
            frameRendering = @"Unknown";
    }
    JRLogInfo(@"Render frames in: %@", frameRendering);
    JRLogInfo(@"Render in Core Video thread: %@",
              mRenderInCoreVideoThread? @"YES" : @"NO");
    
    [mRenderer osd_init: [self openGLContext]
                 format: [self pixelFormat]
                   size: NSIntegralRect([self bounds]).size];
    mStartTime = 0.0;
    
#if MAME_EXPORT_MOVIE
    [self performSelectorOnMainThread: @selector(createMovieExporter)
                           withObject: nil
                        waitUntilDone: YES];
#endif
    
    [self startAnimation];
    [self updateMouseCursor];
    
    return 0;
}

- (void) setSwitchModesForFullScreen: (BOOL) switchModesForFullScreen;
{
    // Turn off fading, if not switching resolutions
    if (!switchModesForFullScreen)
        [self setFadeTime: 0.0];
    else
        [self setFadeTime: 0.25];
    [super setSwitchModesForFullScreen: switchModesForFullScreen];
}

- (void) mameDidExit: (running_machine *) machine;
{
    mPrimitives = 0;
#if MAME_EXPORT_MOVIE
    [self freeMovieExporter];
#endif
    
    [self stopAnimation];
    [mAudioController osd_stop_audio_stream];
    [mRenderer osd_exit];
    //render_target_free(mTarget);
    machine->render().target_free(mTarget);
    
    [mWindowedCiContext release];
    mWindowedCiContext = nil;
    [mFullScreenCiContext release];
    mFullScreenCiContext = nil;
}

- (void) mameDidPause: (running_machine *) machine
                pause: (int) pause; 
{
    JRLogDebug(@"mameDidPause: %d", pause);
    mMameIsPaused = (pause == 1)? YES : NO;
    [mAudioController setPaused: mMameIsPaused];
    [self updateMouseCursor];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown: (NSEvent *) event
{
    // [NSCursor setHiddenUntilMouseMoves: YES];
}

- (void) keyUp: (NSEvent *) event
{
}

- (void) flagsChanged: (NSEvent *) event
{
}

- (void) resize
{
    NSRect bounds = [self activeBounds];
    
	{
        float x = bounds.origin.x;
        float y = bounds.origin.y;
        float w = bounds.size.width;
        float h = bounds.size.height;
        glViewport(x, y, w, h);
        
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, w, 0, h, 0, 1);
        
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
	}
}


//=========================================================== 
//  game 
//=========================================================== 
- (NSString *) game
{
    return [[mGame retain] autorelease]; 
}

- (BOOL) setGame: (NSString *) theGame
{
    if (mGame != theGame)
    {
        [mGame release];
        mGame = [theGame retain];
    }
    
    if (mGame != nil)
    {
        mGameDriver = driver_get_name([mGame UTF8String]);
        if (mGameDriver != NULL)
        {
            MameConfiguration * configuration =
                [MameConfiguration defaultConfiguration];
            [configuration setGameName: mGame];
            return YES;
        }
        else
            return NO;
    }
    else
    {
        mGameDriver == NULL;
        return NO;
    }
}

- (NSString *) gameDescription;
{
    if (mGameDriver != NULL)
        return [NSString stringWithUTF8String: mGameDriver->description];
    else
        return @"";
}


- (BOOL) start;
{
    if (mGameDriver == NULL)
        return NO;
    
    JRLogInfo(@"Running %@", mGame);
    [NSThread detachNewThreadSelector: @selector(gameThread)
                             toTarget: self
                           withObject: nil];

    return YES;
}

- (void) stop;
{
    [mMameLock lock];
    //mame_schedule_exit(mMachine);
    mMachine->schedule_exit();
    [mMameLock unlock];
}

- (void) togglePause;
{
    JRLogDebug(@"togglePause");
    if (!mMameIsRunning)
        return;
    [mMameLock lock];
    {
        //int phase = mame_get_phase(mMachine);
        int phase = mMachine->phase();
        //if (phase == MAME_PHASE_RUNNING)
        if (phase == MACHINE_PHASE_RUNNING)
        {
            //if (mame_is_paused(mMachine))
            //    mame_pause(mMachine, FALSE);
            if (mMachine->paused())
                mMachine->resume();
            else
                //mame_pause(mMachine, TRUE);
                mMachine->paused();
        }
    }
    [mMameLock unlock];
}

- (BOOL) pause: (BOOL) pause
{
    if (!mMameIsRunning)
    {
        return YES;
    }

    int phase;
    BOOL isPaused = NO;
    [mMameLock lock];
    {
        //phase = mame_get_phase(mMachine);
        phase = mMachine->phase();
        //if (phase == MAME_PHASE_RUNNING)
        if (phase == MACHINE_PHASE_RUNNING)
        {
            //isPaused = mame_is_paused(mMachine);
            //mame_pause(mMachine, pause);
            mMachine->paused();
        }
    }
    [mMameLock unlock];

    JRLogDebug(@"pause(%d) = %d, phase: %d", pause, isPaused, phase);
    return isPaused;
}

- (MameFileManager *) fileManager;
{
    return mFileManager;
}

- (BOOL) isRunning;
{
    return mMameIsRunning;
}


- (void) setInputEnabled: (BOOL) inputEnabled;
{
    [mInputController setEnabled: inputEnabled];
}

//=========================================================== 
//  throttled 
//=========================================================== 
- (BOOL) throttled;
{
    BOOL value;
    @synchronized(self)
    {
        value = video_get_throttle();
    }
    return value;
}

- (void) setThrottled: (BOOL) flag;
{
    @synchronized(self)
    {
        video_set_throttle(flag? 1 : 0);
    }
}


- (void) toggleThrottled;
{
    @synchronized(self)
    {
        video_set_throttle(!video_get_throttle());
    }
}

//=========================================================== 
//  shouldHideMouseCursor 
//=========================================================== 
- (BOOL) shouldHideMouseCursor
{
    return mShouldHideMouseCursor;
}

- (void) setShouldHideMouseCursor: (BOOL) flag
{
    mShouldHideMouseCursor = flag;
    [self updateMouseCursor];
}

//=========================================================== 
// - quartzComposerFile
//=========================================================== 
- (NSString *) quartzComposerFile
{
    return mQuartzComposerFile; 
}

//=========================================================== 
// - setQuartzComposerFile:
//=========================================================== 
- (void) setQuartzComposerFile: (NSString *) theQuartzComposerFile
{
    [self lockOpenGLLock];
    [self setQuartzComposerFile: theQuartzComposerFile clearImageEffect: YES];
    [self unlockOpenGLLock];
}

- (void) setQuartzComposerFile: (NSString *) theQuartzComposerFile
              clearImageEffect: (BOOL) clearImageEffect;
{
    if (mQuartzComposerFile != theQuartzComposerFile)
    {
        [mQuartzComposerFile release];
        mQuartzComposerFile = [theQuartzComposerFile retain];
    }
    
    if (clearImageEffect)
        [self setImageEffect: nil];
    
    // Force renderer to reload
    [mWindowedQCRenderer release];
    [mFullScreenQCRenderer release];
    mWindowedQCRenderer = nil;
    mFullScreenQCRenderer = nil;
}

//=========================================================== 
// - imageEffect
//=========================================================== 
- (NSString *) imageEffect
{
    return mImageEffect; 
}

//=========================================================== 
// - setImageEffect:
//=========================================================== 
- (void) setImageEffect: (NSString *) theImageEffect
{
    [self lockOpenGLLock];
    if (mImageEffect != theImageEffect)
    {
        [mImageEffect release];
        mImageEffect = [theImageEffect retain];
    }
    
    [mFilter release];
    mFilter = nil;

    if (theImageEffect != nil)
    {
        [self setQuartzComposerFile: nil clearImageEffect: NO];
        mFilter = [[CIFilter filterWithName: @"MameEffectFilter"] retain];

        NSURL * url = [NSURL fileURLWithPath: mImageEffect];
        CIImage * effectImage = [CIImage imageWithContentsOfURL: url];
        [mFilter setValue: effectImage forKey: @"effectImage"];
    }
    [self unlockOpenGLLock];
}

#pragma mark -
#pragma mark Audio

//=========================================================== 
//  audioEnabled 
//=========================================================== 
- (BOOL) audioEnabled
{
    return [mAudioController enabled];
}

- (void) setAudioEnabled: (BOOL) flag
{
    [mAudioController setEnabled: flag];
}

- (BOOL) audioEffectEnabled;
{
    return [mAudioController effectEnabled];
}

- (void) setAudioEffectEnabled: (BOOL) flag;
{
    [mAudioController setEffectEnabled: flag];
}

- (NSArray *) audioEffectComponents;
{
    return [mAudioController effectComponents];
}

- (unsigned) indexOfCurrentEffect;
{
    return [mAudioController indexOfCurrentEffect];
}

- (void) setIndexOfCurrentEffect: (unsigned) indexOfCurrentEffect;
{
    [mAudioController setIndexOfCurrentEffect: indexOfCurrentEffect];
}

- (NSView *) createAudioEffectViewWithSize: (NSSize) size;
{
    return [mAudioController createEffectViewWithSize: size];
}

- (NSArray *) audioEffectFactoryPresets;
{
    return [mAudioController effectFactoryPresets];
}

- (unsigned) indexOfCurrentFactoryPreset;
{
    return [mAudioController indexOfCurrentFactoryPreset];
}

- (void) setIndexOfCurrentFactoryPreset: (unsigned) index;
{
    [mAudioController setIndexOfCurrentFactoryPreset: index];
}

- (float) audioCpuLoad;
{
    return [mAudioController cpuLoad];
}

#pragma mark -

- (BOOL) linearFilter;
{
    return [mRenderer linearFilter];
}

- (void) setLinearFilter: (BOOL) linearFilter;
{
    [mRenderer setLinearFilter: linearFilter];
}

#pragma mark -
#pragma mark OS Dependent API

- (void) osd_update: (int) skip_redraw;
{
    // Drain the pool
    [mMamePool release];
    mMamePool = [[NSAutoreleasePool alloc] init];
    
    if (!skip_redraw)
        [self updateVideo];
    
    // Open lock briefly to allow pending MAME calls
    [mMameLock unlock];
    [mMameLock lock];
    
    // Poll the run loop
#if 0
    [[NSRunLoop currentRunLoop] acceptInputForMode: NSDefaultRunLoopMode
                                        beforeDate: 0];
#else
    [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                             beforeDate: [NSDate date]];
#endif
}

- (void) osd_output_error: (const char *) utf8Format
                arguments: (va_list) argptr;
{
    if ([mDelegate respondsToSelector: @selector(mameErrorMessage:)])
    {
        NSString * message = [self formatOutputMessage: utf8Format
                                             arguments: argptr];
        [mDelegate performSelectorOnMainThread: @selector(mameErrorMessage:)
                                    withObject: message
                                 waitUntilDone: NO];
    }
}

- (void) osd_output_warning: (const char *) utf8Format
                  arguments: (va_list) argptr;
{
    if ([mDelegate respondsToSelector: @selector(mameWarningMessage:)])
    {
        NSString * message = [self formatOutputMessage: utf8Format
                                             arguments: argptr];
        [mDelegate performSelectorOnMainThread: @selector(mameWarningMessage:)
                                    withObject: message
                                 waitUntilDone: NO];
    }
}

- (void) osd_output_info: (const char *) utf8Format
               arguments: (va_list) argptr;
{
    if ([mDelegate respondsToSelector: @selector(mameInfoMessage:)])
    {
        NSString * message = [self formatOutputMessage: utf8Format
                                             arguments: argptr];
        [mDelegate performSelectorOnMainThread: @selector(mameInfoMessage:)
                                    withObject: message
                                 waitUntilDone: NO];
    }
}

- (void) osd_output_debug: (const char *) utf8Format
                arguments: (va_list) argptr;
{
    if ([mDelegate respondsToSelector: @selector(mameDebugMessage:)])
    {
        NSString * message = [self formatOutputMessage: utf8Format
                                             arguments: argptr];
        [mDelegate performSelectorOnMainThread: @selector(mameDebugMessage:)
                                    withObject: message
                                 waitUntilDone: NO];
    }
}

- (void) osd_output_log: (const char *) utf8Format
              arguments: (va_list) argptr;
{
    if ([mDelegate respondsToSelector: @selector(mameLogMessage:)])
    {
        NSString * message = [self formatOutputMessage: utf8Format
                                             arguments: argptr];
        [mDelegate performSelectorOnMainThread: @selector(mameLogMessage:)
                                    withObject: message
                                 waitUntilDone: NO];
    }
}


- (id) delegagte;
{
    return mDelegate;
}

- (void) setDelegate: (id) delegate;
{
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    if (mDelegate != nil)
        [center removeObserver: mDelegate name: nil object: self];
        
    mDelegate = delegate;
    
    // repeat  the following for each notification
    if ([mDelegate respondsToSelector: @selector(mameWillStartGame:)])
    {
        [center addObserver: mDelegate selector: @selector(mameWillStartGame:)
                       name: MameWillStartGame object: self];
    }
    if ([mDelegate respondsToSelector: @selector(mameDidFinishGame:)])
    {
        [center addObserver: mDelegate selector: @selector(mameDidFinishGame:)
                       name: MameDidFinishGame object: self];
    }
}

@end

@implementation MameView (Private)

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object 
                         change: (NSDictionary *) change
                        context: (void *) context;
{
    JRLogDebug(@"observeValueForKeyPath: %@ ofObject: %@", keyPath, object);
    if ((object == mTimingController) &&
        [keyPath isEqualToString: @"throttled"])
    {
        [self willChangeValueForKey: @"throttled"];
        [self didChangeValueForKey: @"throttled"];
    }
}

- (BOOL) isCoreImageAccelerated;
{
    
    // This code fragment is from the VideoViewer sample code
    [[self openGLContext] makeCurrentContext];
    // CoreImage might be too slow if the current renderer doesn't support GL_ARB_fragment_program
    const GLubyte * glExtensions = glGetString(GL_EXTENSIONS);
    const GLubyte * extension = (const GLubyte *)"GL_ARB_fragment_program";
    return gluCheckExtension(extension, glExtensions);
}

- (BOOL) hasMultipleCPUs;
{
	host_basic_info_data_t hostInfo;
	mach_msg_type_number_t infoCount;
	
	infoCount = HOST_BASIC_INFO_COUNT;
    
	host_info((host_t)mach_host_self(), (host_flavor_t)HOST_BASIC_INFO, 
			  (host_info_t)&hostInfo, (mach_msg_type_number_t*)&infoCount);
    if (hostInfo.avail_cpus > 1)
        return YES;
    else
        return NO;
}

- (void) gameThread
{
#if DEBUG_INSTRUMENTED
    chudInitialize();	  
    chudMarkPID(getpid(), 1);
    chudAcquireRemoteAccess();
    chudStartRemotePerfMonitor("MAME OS X gameThread");
    chudRecordSignPost(MameGameStart, chudPointSignPost, 0, 0, 0, 0);
#endif
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [mMameLock lock];
    mMamePool = [[NSAutoreleasePool alloc] init];
    mMameIsRunning = YES;
    mMameIsPaused = NO;
    // [self updateMouseCursor];
    
    MameConfiguration * configuration =
        [MameConfiguration defaultConfiguration];
    int exitStatus = mame_execute([configuration coreOptions]);
    mMameIsRunning = NO;
    mMameIsPaused = NO;
    [self updateMouseCursor];
    [mMamePool release];
    [mMameLock unlock];
    
    JRLogInfo(@"Average FPS displayed: %f (%qi frames)\n",
              [mTimingController fpsDisplayed],
              [mTimingController framesDisplayed]);
    JRLogInfo(@"Average FPS rendered: %f (%qi frames)\n",
              [mTimingController fpsRendered],
              [mTimingController framesRendered]);
    [mTimingController gameFinished];
    [mInputController gameFinished];

    [self performSelectorOnMainThread: @selector(gameFinished:)
                           withObject: [NSNumber numberWithInt: exitStatus]
                        waitUntilDone: NO];
    
    [pool release];

#ifdef DEBUG_INSTRUMENTED
	chudRecordSignPost(MameGameEnd, chudPointSignPost, 0, 0, 0, 0);
    chudStopRemotePerfMonitor();
    chudReleaseRemoteAccess();
	chudCleanup();
#endif
}

- (void) gameFinished: (NSNumber *) exitStatus;
{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        exitStatus, MameExitStatusKey,
        nil];
    [[NSNotificationCenter defaultCenter] postNotificationName: MameDidFinishGame
                                                        object: self
                                                      userInfo: userInfo];
}

- (void) willEnterFullScreen;
{
    mUnpauseOnFullScreenTransition = [self pause: YES];
}

- (void) willExitFullScreen;
{
    mUnpauseOnFullScreenTransition = [self pause: YES];
}

- (void) didEnterFullScreen: (NSSize) fullScreenSize;
{
    switch (mFullScreenZoom)
    {
        case MameFullScreenIntegral:
            mFullScreenSize = [self integralStretchedSize: fullScreenSize];
            break;
            
        case MameFullScreenIndependentIntegral:
            mFullScreenSize =
                [self independentIntegralStretchedSize: fullScreenSize];
            break;
            
        case MameFullScreenStretch:
            mFullScreenSize = fullScreenSize;
            break;
            
        case MameFullScreenMaximum:
        default:
            mFullScreenSize = [self stretchedSize: fullScreenSize];
            break;
    }

    JRLogInfo(@"Full screen size: %@ of %@", NSStringFromSize(mFullScreenSize),
              NSStringFromSize(fullScreenSize));
 
    [self pause: mUnpauseOnFullScreenTransition];
}

- (void) didExitFullScreen;
{
    [self pause: mUnpauseOnFullScreenTransition];
}

- (void) updateMouseCursor;
{
    BOOL hideCursor = (mMameIsRunning && !mMameIsPaused && mShouldHideMouseCursor);
    SEL selector;
    if (hideCursor)
        selector = @selector(hideMouseCursor);
    else
        selector = @selector(showMouseCursor);
    
    [self performSelectorOnMainThread: selector
                           withObject: nil
                        waitUntilDone: NO];
}

- (void) hideMouseCursor;
{
    if (mMouseCursorIsHidden)
        return;
    
    [[self window] makeKeyAndOrderFront: self];
    [NSCursor hide];
    CGAssociateMouseAndMouseCursorPosition(NO);
    
    // Even though the mouse cursor is hidden, and it won't move, mouse clicks
    // still register.  If cursor is not over our window, it will bring
    // another app to the foreground.  So, this code moves the cursor
    // to the cener of our view, so mouse clicks have no side effects.
    NSRect bounds = [self bounds];
    NSPoint midpoint = NSMakePoint(bounds.origin.x + bounds.size.width/2,
                                   bounds.origin.y + bounds.size.height/2);
    NSPoint midpointInWindowCoordinates =
        [self convertPoint: midpoint toView: nil];
    NSWindow * window = [self window];
    NSPoint midpointInScreenCoordinates =
        [window convertBaseToScreen: midpointInWindowCoordinates];
    
    // Cocoa screen coordinates have (0,0) in the lower left.  Core Graphics
    // screen coordinates have (0,0) in the upper left.  This translates the
    // Y-coordinate from Cocoa to CG screen coordinates.
    NSScreen * screen = [window screen];
    CGDirectDisplayID display =
        (CGDirectDisplayID)[[[screen deviceDescription] objectForKey: @"NSScreenNumber"] intValue];
    
    size_t height = CGDisplayPixelsHigh(display);
    CGPoint midpointInDisplayCoordinates =
        CGPointMake(midpointInScreenCoordinates.x,
                    height - midpointInScreenCoordinates.y);

    CGDisplayMoveCursorToPoint(display, midpointInDisplayCoordinates);
    mMouseCursorIsHidden = YES;
}

- (void) showMouseCursor;
{
    if (!mMouseCursorIsHidden)
        return;
    
    [NSCursor unhide];
    CGAssociateMouseAndMouseCursorPosition(YES);
    mMouseCursorIsHidden = NO;
}

#pragma mark -
#pragma mark "Notifications and Delegates"

- (void) sendMameWillStartGame;
{
    [[NSNotificationCenter defaultCenter] postNotificationName: MameWillStartGame
                                                        object: self];
}

- (void) sendMameDidFinishGame;
{
}

- (NSString *) formatOutputMessage: (const char *) utf8Format
                         arguments: (va_list) argptr;
{
    NSString * format = [NSString stringWithUTF8String: utf8Format];
    return [[[NSString alloc] initWithFormat: format
                                   arguments: argptr] autorelease];
}

#pragma mark -
#pragma mark "Frame Drawing"

- (NSRect) centerNSSize: (NSSize) size withinRect: (NSRect) rect;
{
    rect.origin.x = roundf((rect.size.width - size.width) / 2);
    rect.origin.y = roundf((rect.size.height - size.height) / 2);
    rect.size = size;
    return rect;
}

- (void) drawFrame;
{
    [self resize];
    
    NSOpenGLContext * currentContext = [self activeOpenGLContext];
    static osd_lock *render_lock;
    render_lock = osd_lock_alloc();
    
    if (mRenderInCoreVideoThread)
    {
        render_primitive_list * primitives = 0;
        NSSize renderSize;
        @synchronized(self)
        {
            primitives = mPrimitives;
            renderSize = mRenderSize;
            mPrimitives = 0;
        }
        
        if (primitives != 0)
        {
            osd_lock_acquire(render_lock);
            //osd_lock_acquire(primitives->lock);
            //osd_lock_acquire(osd_lock_alloc());
            //primitives->acquire_lock();
            //if (primitives->head != NULL)
            if (primitives->first() != NULL)
            {
                [mRenderer renderFrame: primitives
                              withSize: renderSize];
#ifdef DEBUG_INSTRUMENTED
                chudRecordSignPost(MameRenderFrame, chudPointSignPost, primitives->head, 0, 0, 0);
#endif
            }
            //osd_lock_release(primitives->lock);
            //osd_lock_release(osd_lock_alloc());
            osd_lock_release(render_lock);
        }
    }
    
    [currentContext makeCurrentContext];
    
    if (mClearToRed)
        glClearColor(1.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CVOpenGLTextureRef frame = [mRenderer currentFrameTexture];
    if (frame == NULL)
    {
        JRLogDebug(@"Null frame");
        return;
    }
    
    NSRect currentBounds = [self activeBounds];
    NSSize destSize;
    if ([self fullScreen])
    {
        destSize = mRenderSize;
    }
    else
    {
        // Stretch again, since the render size could be slightly different
        // than the current size, if we're in the middle of a resize.
        // Turn on "clear to read" and use mRenderSize to see why.
        destSize = [self stretchedSize: currentBounds.size];
    }
    NSRect destRect = [self centerNSSize: destSize withinRect: currentBounds];
    
    if (mFrameRenderingOption == MameRenderFrameInCoreImage)
        [self drawFrameUsingCoreImage: frame inRect: destRect];
    else if (mFrameRenderingOption == MameRenderFrameInQCComposition)
        [self drawFrameUsingQCRenderer: frame inRect: destRect];
    else
        [self drawFrameUsingOpenGL: frame inRect: destRect];
    
    
#if MAME_EXPORT_MOVIE
    [self exportMovieFrame];
#endif
    
    [mTimingController frameWasDisplayed];
    return;
}

- (void) drawFrameUsingCoreImage: (CVOpenGLTextureRef) frame
                          inRect: (NSRect) destRect;
{
    CIImage * frameImage = [CIImage imageWithCVImageBuffer: frame];
    CIContext * ciContext = [self ciContext];

    CGRect frameRect = [frameImage extent];
    NSSize frameSize = NSMakeSize(frameRect.size.width, frameRect.size.height);
    if (mFilter != nil)
    {
        [mFilter setValue: frameImage forKey: @"inputImage"];
        frameImage = [mFilter valueForKey: @"outputImage"];
    }
    frameRect = [frameImage extent];
    
    [ciContext drawImage: frameImage
                  inRect: *(CGRect *) &destRect
                fromRect: frameRect];
}

- (QCRenderer *) createQCRenderer;
{
    if (mQuartzComposerFile == nil)
        return nil;
    QCRenderer * renderer =
        [[QCRenderer alloc] initWithOpenGLContext: [self activeOpenGLContext]
                                     pixelFormat: [self activePixelFormat]
                                            file: mQuartzComposerFile];
    NSArray * inputKeys = [renderer inputKeys];
    if (![inputKeys containsObject: @"Frame"])
    {
        JRLogError(@"QC composition is missing the Frame published input: %@",
                   mQuartzComposerFile);
        [renderer release];
        return nil;
    }
    mRendererHasWidth = [inputKeys containsObject: @"Width"];
    mRendererHasHeight = [inputKeys containsObject: @"Height"];
    return renderer;
}

- (QCRenderer *) activeQCRenderer;
{
    [self lockOpenGLLock];
    QCRenderer * renderer = nil;
    if ([self fullScreen])
    {
        [mWindowedQCRenderer release];
        mWindowedQCRenderer = nil;
        if (mFullScreenQCRenderer == nil)
            mFullScreenQCRenderer = [self createQCRenderer];
        renderer = mFullScreenQCRenderer;
    }
    else
    {
        [mFullScreenQCRenderer release];
        mFullScreenQCRenderer = nil;
        if (mWindowedQCRenderer == nil)
            mWindowedQCRenderer = [self createQCRenderer];
        renderer = mWindowedQCRenderer;
    }
    [self unlockOpenGLLock];
    return renderer;
}

- (void) drawFrameUsingQCRenderer: (CVOpenGLTextureRef) frame
                           inRect: (NSRect) destRect;
{
    QCRenderer * renderer = [self activeQCRenderer];
    if (renderer == nil)
    {
        [self drawFrameUsingCoreImage: frame inRect: destRect];
        return;
    }

    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];

    if(mStartTime == 0)
    {
        mStartTime = time;
        time = 0;
    }
    else
        time -= mStartTime;

    NSRect currentBounds = [self activeBounds];
    if (mRendererHasWidth)
    {
        float width = destRect.size.width/currentBounds.size.width * 2.0;
        [renderer setValue: [NSNumber numberWithFloat: width] forInputKey: @"Width"];
    }
    
    if (mRendererHasHeight)
    {
        // Max height = 2 / aspect ratio
        //            = currentBounds.size.height/currentBounds.size.width * 2.0;
        float height = destRect.size.height/currentBounds.size.width * 2.0;
        [renderer setValue: [NSNumber numberWithFloat: height] forInputKey: @"Height"];
    }

    [renderer setValue: (id) frame forInputKey: @"Frame"];
    if (![renderer renderAtTime: time arguments: [NSDictionary dictionary]])
        JRLogError(@"Rendering failed at time %.3fs", time);
}

- (void) drawFrameUsingOpenGL: (CVOpenGLTextureRef) frame
                       inRect: (NSRect) destRect;
{
    GLfloat vertices[4][2];
    GLfloat texCoords[4][2];
    
    // Configure OpenGL to get vertex and texture coordinates from our two arrays
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
    
    // Specify video rectangle vertices counter-clockwise from the
    // origin (lower left) after centering

    vertices[0][0] = destRect.origin.x;
    vertices[0][1] = destRect.origin.y;
    vertices[1][0] = NSMaxX(destRect);
    vertices[1][1] = destRect.origin.y;
    vertices[2][0] = NSMaxX(destRect);
    vertices[2][1] = NSMaxY(destRect);
    vertices[3][0] = destRect.origin.x;
    vertices[3][1] = NSMaxY(destRect);
    
    GLenum textureTarget = CVOpenGLTextureGetTarget(frame);
    // textureTarget = GL_TEXTURE_RECTANGLE_ARB;

    glEnable(textureTarget);
    glTexParameteri(textureTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(textureTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    // Get the current texture's coordinates, bind the texture, and draw our rectangle
    CVOpenGLTextureGetCleanTexCoords(frame, texCoords[0], texCoords[1], texCoords[2], texCoords[3]);
    glBindTexture(textureTarget, CVOpenGLTextureGetName(frame));
    glDrawArrays(GL_QUADS, 0, 4);
    glDisable(textureTarget);
}

- (void) updateVideo;
{
    NSSize renderSize;
    char code;
    if ([self fullScreen])
    {
        renderSize = mFullScreenSize;
        code = 'F';
    }
    else
    {
        renderSize = [self stretchedSize: [self activeBounds].size];
        code = 'W';
    }

    //render_target_set_max_update_rate(mTarget, mRefreshRate);
    mTarget->set_max_update_rate(mRefreshRate);
    if (mRenderInCoreVideoThread)
    {
        //render_target_set_bounds(mTarget, renderSize.width, renderSize.height,
        //                         mPixelAspectRatio);
        mTarget->set_bounds(renderSize.width, renderSize.height, mPixelAspectRatio);
        //const render_primitive_list * primitives = render_target_get_primitives(mTarget);
        render_primitive_list & primitives = mTarget->get_primitives();
#ifdef DEBUG_INSTRUMENTED
        chudRecordSignPost(MameGetPrimitives, chudPointSignPost, primitives->head, 0, 0, 0);
#endif
        @synchronized(self)
        {
            mRenderSize = renderSize;
            //mPrimitives = primitives;
            mPrimitives = &primitives;
        }
    }
    else
    {
        [self lockOpenGLLock];
        
        //render_target_set_bounds(mTarget, renderSize.width, renderSize.height,
        //                         mPixelAspectRatio);
        mTarget->set_bounds(renderSize.width, renderSize.height, mPixelAspectRatio);
        //const render_primitive_list * primitives = render_target_get_primitives(mTarget);
        render_primitive_list & primitives = mTarget->get_primitives();
#ifdef DEBUG_INSTRUMENTED
        chudRecordSignPost(MameGetPrimitives, chudPointSignPost, primitives->head, 0, 0, 0);
#endif
        [mRenderer renderFrame: &primitives
                      withSize: renderSize];
#ifdef DEBUG_INSTRUMENTED
        chudRecordSignPost(MameRenderFrame, chudPointSignPost, primitives->head, 0, 0, 0);
#endif
        mRenderSize = renderSize;
        
        [self unlockOpenGLLock];
    }
    
    [mTimingController frameWasRendered];
}

- (void) updateDisplayProperties;
{
    mPixelAspectRatio = 0.0;
    mRefreshRate = 0.0;
    [self setPropertiesWithDisplay: kCGDirectMainDisplay];
}

#define NSSTR(_cString_) [NSString stringWithCString: _cString_]

#define kIOFBTransformKey               "IOFBTransform"
enum {
    // transforms
    kIOFBRotateFlags                    = 0x0000000f,
    
    kIOFBSwapAxes                       = 0x00000001,
    kIOFBInvertX                        = 0x00000002,
    kIOFBInvertY                        = 0x00000004,
    
    kIOFBRotate0                        = 0x00000000,
    kIOFBRotate90                       = kIOFBSwapAxes | kIOFBInvertX,
    kIOFBRotate180                      = kIOFBInvertX  | kIOFBInvertY,
    kIOFBRotate270                      = kIOFBSwapAxes | kIOFBInvertY
};


// For aspect ratio calculation, see:
// http://developer.apple.com/qa/qa2001/qa1217.html
- (void) setPropertiesWithDisplay: (CGDirectDisplayID) displayId;
{
    // Assume square pixels, if we can't determine it.
    float aspectRatio = 1.0;
    
    //    Grab a connection to IOKit for the requested display
    io_connect_t displayPort = CGDisplayIOServicePort(displayId);
    if (displayPort != MACH_PORT_NULL)
    {
        //    Find out what IOKit knows about this display
        NSDictionary * displayDict = (NSDictionary *)
            IODisplayCreateInfoDictionary(displayPort, 0);
            //IODisplayCreateInfoDictionary(displayPort, 0);
        if (displayDict != nil)
        {
            JRLogDebug(@"displayDict: %@", displayDict);
            // These sizes are in millimeters (mm)
            float horizontalSize =
                [[displayDict objectForKey: NSSTR(kDisplayHorizontalImageSize)]
                    floatValue];
            float verticalSize =
                [[displayDict objectForKey: NSSTR(kDisplayVerticalImageSize)]
                    floatValue];
                
            uint32_t rotation =
                [[displayDict objectForKey: NSSTR(kIOFBTransformKey)]
                    unsignedIntValue];

            // Make sure to release the dictionary we got from IOKit
            [displayDict release];
            
            if ((horizontalSize == 0.0) || (verticalSize == 0.0))
            {
                JRLogInfo(@"Horizontal or vertical display size is zero.");
            }
            else
            {
                NSDictionary * displayMode = (NSDictionary *) CGDisplayCurrentMode(displayId);
                JRLogDebug(@"displayMode: %@", displayMode);

                float displayWidth =
                    [[displayMode objectForKey: (NSString *) kCGDisplayWidth]
                        floatValue];
                float displayHeight =
                    [[displayMode objectForKey: (NSString *)  kCGDisplayHeight]
                        floatValue];
                double refreshRate = [[displayMode objectForKey: (NSString *) kCGDisplayRefreshRate] doubleValue];

                if (refreshRate == 0)
                {
                    // LCDs report 0, but they're effectively 60Hz.
                    JRLogInfo(@"Detected refresh of 0, defaulting to 60");
                    mRefreshRate = 60.0;
                }
                else
                    mRefreshRate = refreshRate;
                
                float horizontalPixelsPerMM;
                float verticalPixlesPerMM;
                if ((rotation == kIOFBRotate90) || (rotation == kIOFBRotate270))
                {
                    horizontalPixelsPerMM = displayHeight/horizontalSize;
                    verticalPixlesPerMM = displayWidth/verticalSize;
                }
                else
                {
                    horizontalPixelsPerMM = displayWidth/horizontalSize;
                    verticalPixlesPerMM = displayHeight/verticalSize;
                }
                aspectRatio = horizontalPixelsPerMM/verticalPixlesPerMM;
            }
        }
    }

    if (mKeepAspectRatio)
        mPixelAspectRatio = aspectRatio;
}

#if MAME_EXPORT_MOVIE

static FrameMovieExporter * _exporter = nil;
static FrameReader * _reader = nil;

- (void) createMovieExporter;
{
    NSSize size = NSIntegralRect([self bounds]).size;
    
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
	double							framerate = 60.0;
	CodecType						codec;
	ICMCompressionSessionOptionsRef options;
    
    [savePanel setRequiredFileType:@"mov"];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    if(([savePanel runModalForDirectory:[@"~/Desktop" stringByExpandingTildeInPath]
                                   file: mGame] == NSOKButton) &&
       (options = [FrameCompressor userOptions:&codec frameRate:&framerate autosaveName:@"CompressionDialogSettings"]))
        //        (options = [FrameCompressor defaultOptions]))
    {
        _reader = [[FrameReader alloc] initWithOpenGLContext: [self openGLContext] pixelsWide:size.width pixelsHigh:size.height asynchronousFetching:YES];
        _exporter = [[FrameMovieExporter alloc] initWithPath:[savePanel filename] codec:codec pixelsWide:size.width pixelsHigh:size.height options:options];
        if(_exporter == nil) {
            [_reader release];
            _reader = nil;
        }
    }
    if(_exporter == nil) {
        NSBeep();
    }
}

- (void) exportMovieFrame;
{
    if(_exporter)
    {
        static NSTimeInterval _startTime = 0.0;
        NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
        if(_startTime == 0.0)
            _startTime = time;
        time = time - _startTime;
        
        CVPixelBufferRef frame;
        frame = [_reader readFrame];
		if(frame)
            [_exporter exportFrame: frame timeStamp: time];
    }
}

- (void) freeMovieExporter;
{
	if(_exporter)
    {
        FrameMovieExporter * exporter = _exporter;
        _exporter = 0;
		[exporter release];
        [_reader release];
        _reader = nil;
    }
}

#endif

@end

