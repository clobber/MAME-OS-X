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
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "DDCustomOpenGLView.h"

#include "osdepend.h"
#include "render.h"
#include "emu.h"

@class MameController;
@class MameRenderer;
@class MameInputController;
@class MameAudioController;
@class MameTimingController;
@class MameFileManager;
@class MameConfiguration;
@class MameFilter;
@class QCRenderer;

typedef enum _MameFrameRenderingOption
{
    MameRenderFrameInOpenGL,
    MameRenderFrameInCoreImage,
    MameRenderFrameInQCComposition,
} MameFrameRenderingOption;

typedef enum _MameFullScreenZoom
{
    MameFullScreenMaximum,
    MameFullScreenIntegral,
    MameFullScreenIndependentIntegral,
    MameFullScreenStretch,
} MameFullScreenZoom;

@interface MameView : DDCustomOpenGLView
{
    IBOutlet MameController * mController;
    CIContext * mWindowedCiContext;
    CIContext * mFullScreenCiContext;

    QCRenderer * mWindowedQCRenderer;
    QCRenderer * mFullScreenQCRenderer;
    BOOL mRendererHasWidth;
    BOOL mRendererHasHeight;
    
    id mDelegate;
    
    NSString * mGame;
    const game_driver * mGameDriver;

    running_machine * mMachine;
    render_target * mTarget;
    //const render_primitive_list * mPrimitives;
    render_primitive_list * mPrimitives;
    MameRenderer * mRenderer;
    MameFrameRenderingOption mFrameRenderingOption;
    NSSize mRenderSize;
    float mPixelAspectRatio;
    double mRefreshRate;
    
    BOOL mRenderInCoreVideoThread;
    CIFilter * mFilter;
    NSSize mNaturalSize;
    NSSize mOptimalSize;
    NSSize mFullScreenSize;
    BOOL mKeepAspectRatio;
    BOOL mClearToRed;
    MameFullScreenZoom mFullScreenZoom;
    NSString * mQuartzComposerFile;
    NSString * mImageEffect;
    NSTimeInterval mStartTime;
    
    MameInputController * mInputController;
    MameAudioController * mAudioController;
    MameTimingController * mTimingController;
    MameFileManager * mFileManager;

    BOOL mMameIsRunning;
    BOOL mMameIsPaused;
    BOOL mMouseCursorIsHidden;
    BOOL mShouldHideMouseCursor;
    NSLock * mMameLock;
    NSAutoreleasePool * mMamePool;

    BOOL mThrottled;
    
    BOOL mUnpauseOnFullScreenTransition;
}

- (NSString *) game;
- (BOOL) setGame: (NSString *) theGame;
- (NSString *) gameDescription;

- (BOOL) start;
- (void) stop;
- (void) togglePause;
- (BOOL) isRunning;

- (void) setInputEnabled: (BOOL) inputEnabled;

#pragma mark -
#pragma mark Sizing

- (NSSize) naturalSize;
- (NSSize) optimalSize;

- (BOOL) keepAspectRatio;
- (void) setKeepAspectRatio: (BOOL) keepAspectRatio;

- (NSSize) stretchedSize: (NSSize) boundingSize;
- (NSSize) integralStretchedSize: (NSSize) boundingSize;
- (NSSize) independentIntegralStretchedSize: (NSSize) boundingSize;

- (MameFullScreenZoom) fullScreenZoom;
- (void) setFullScreenZoom: (MameFullScreenZoom) fullScreenZoom;

#pragma mark -
#pragma mark Rendering

- (MameFrameRenderingOption) frameRenderingOption;
- (void) setFrameRenderingOption:
    (MameFrameRenderingOption) frameRenderingOption;
- (MameFrameRenderingOption) frameRenderingOptionDefault;

- (BOOL) renderInCoreVideoThread;
- (void) setRenderInCoreVideoThread: (BOOL) flag;
- (BOOL) renderInCoreVideoThreadDefault;

- (BOOL) clearToRed;
- (void) setClearToRed: (BOOL) clearToRed;

- (void) createCIContext;
- (CIContext *) ciContext;

- (MameFileManager *) fileManager;

- (BOOL) throttled;
- (void) setThrottled: (BOOL) flag;
- (void) toggleThrottled;

- (BOOL) shouldHideMouseCursor;
- (void) setShouldHideMouseCursor: (BOOL) flag;

- (NSString *) quartzComposerFile;
- (void) setQuartzComposerFile: (NSString *) theQuartzComposerFile;

- (void) setQuartzComposerFile: (NSString *) theQuartzComposerFile
              clearImageEffect: (BOOL) clearImageEffect;

- (NSString *) imageEffect;
- (void) setImageEffect: (NSString *) theImageEffect;

#pragma mark -
#pragma mark Audio

- (BOOL) audioEnabled;
- (void) setAudioEnabled: (BOOL) flag;

- (BOOL) audioEffectEnabled;
- (void) setAudioEffectEnabled: (BOOL) flag;

- (NSArray *) audioEffectComponents;

- (unsigned) indexOfCurrentEffect;
- (void) setIndexOfCurrentEffect: (unsigned) indexOfCurrentEffect;

- (NSView *) createAudioEffectViewWithSize: (NSSize) size;

- (NSArray *) audioEffectFactoryPresets;

- (unsigned) indexOfCurrentFactoryPreset;
- (void) setIndexOfCurrentFactoryPreset: (unsigned) index;

- (float) audioCpuLoad;

#pragma mark -

- (BOOL) linearFilter;
- (void) setLinearFilter: (BOOL) linearFilter;

- (int) osd_init: (running_machine *) machine;

- (void) mameDidExit: (running_machine *) machine;

- (void) mameDidPause: (running_machine *) machine
                pause: (int) pause; 

#pragma mark -
#pragma mark OS Dependent API

- (void) osd_update: (int) skip_redraw;

- (void) osd_output_error: (const char *) utf8Format
                arguments: (va_list) argptr;

- (void) osd_output_warning: (const char *) utf8Format
                  arguments: (va_list) argptr;

- (void) osd_output_info: (const char *) utf8Format
               arguments: (va_list) argptr;

- (void) osd_output_debug: (const char *) utf8Format
                arguments: (va_list) argptr;

- (void) osd_output_log: (const char *) utf8Format
              arguments: (va_list) argptr;

- (id) delegagte;
- (void) setDelegate: (id) delegate;

@end

@interface NSObject (MameViewDelegateMethods)

- (void) mameWillStartGame: (NSNotification *) notification;

- (void) mameDidFinishGame: (NSNotification *) notification;

- (void) mameErrorMessage: (NSString *) message;

- (void) mameWarningMessage: (NSString *) message;

- (void) mameInfoMessage: (NSString *) message;

- (void) mameDebugMessage: (NSString *) message;

- (void) mameLogMessage: (NSString *) message;

@end

extern NSString * MameWillStartGame;
extern NSString * MameDidFinishGame;
extern NSString * MameExitStatusKey;

// These should corresponed to MAMERR_* in mame.h

enum
{
    MameExitStatusSuccess = 0,
    MameExitStatusFailedValidity = 1,
    MameExitStatusMissingFiles = 2,
    MameExitStatusFatalError = 3
};

