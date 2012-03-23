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

#import "AudioEffectWindowController.h"
#import "MameView.h"
#import "DDAudioComponent.h"

@interface AudioEffectWindowController (Private)

- (void) updateCpuLoad: (NSTimer*) theTimer;
- (void) updateAudioUnitView;
- (void) auViewDidChange: (NSNotification *) notification;
- (void) setAudioUnitView: (NSView *) view;
- (void) windowResizeFinished: (NSTimer*) theTimer;

@end

@implementation AudioEffectWindowController

- (id) initWithMameView: (MameView *) mameView;
{
    self = [super initWithWindowNibName: @"AudioEffects"];
    if (self == nil)
        return nil;
    
    mMameView = [mameView retain];
    mAudioUnitView = nil;
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: nil
                                                  object: mAudioUnitView];
    [mMameView release];
    [mAudioUnitView release];
    [mCpuLoadTimer release];
    [super dealloc];
}

- (void) observeValueForKeyPath: (NSString *) keyPath
                       ofObject: (id) object 
                         change: (NSDictionary *) change
                        context: (void *) context;
{
    if ((object == mMameView) &&
        [keyPath isEqualToString: @"indexOfCurrentEffect"])
    {
        [self updateAudioUnitView];
    }
    else if ((object == mMameView) &&
             [keyPath isEqualToString: @"audioEffectFactoryPresets"])
    {
        [self willChangeValueForKey: @"effectHasFactoryPresets"];
        [self didChangeValueForKey: @"effectHasFactoryPresets"];
    }
}

- (void) awakeFromNib;
{
    [self updateAudioUnitView];

    // The panel should be a utility panel, but not floating.  This cannot
    // be set in Interface Builder.
    NSPanel * panel = (NSPanel *) [self window];
    [panel setFloatingPanel: NO];
    
    [mMameView addObserver: self
                forKeyPath: @"indexOfCurrentEffect"
                   options: 0
                   context: nil];
    
    [mMameView addObserver: self
                forKeyPath: @"audioEffectFactoryPresets"
                   options: 0
                   context: nil];
}

- (MameView *) mameView;
{
    return mMameView;
}

- (float) cpuLoad;
{
    return mCpuLoad;
}

- (IBAction) showWindow: (id) sender;
{
    [super showWindow: sender];
    
    [self updateCpuLoad: nil];
    if (mCpuLoadTimer == nil)
    {
        mCpuLoadTimer =
            [NSTimer scheduledTimerWithTimeInterval: 1.0
                                             target: self
                                           selector: @selector(updateCpuLoad:)
                                           userInfo: nil
                                            repeats: YES];
        [mCpuLoadTimer retain];
    }
}

- (BOOL) effectHasFactoryPresets;
{
    return ([[mMameView audioEffectFactoryPresets] count] > 0);
}

- (void) windowWillClose: (NSNotification *) notification;
{
    if (mCpuLoadTimer != nil)
    {
        [mCpuLoadTimer invalidate];
        [mCpuLoadTimer release];
        mCpuLoadTimer = nil;
    }
}

@end

@implementation AudioEffectWindowController (Private)

- (void) updateCpuLoad: (NSTimer*) theTimer;
{
    [self willChangeValueForKey: @"cpuLoad"];
    mCpuLoad = [mMameView audioCpuLoad] * 100.0;
    [self didChangeValueForKey: @"cpuLoad"];
}

- (void) updateAudioUnitView;
{
    NSView * view = [mMameView createAudioEffectViewWithSize: NSMakeSize(400, 300)];
    [self setAudioUnitView: view];
}

- (void) auViewDidChange: (NSNotification *) notification;
{
    NSWindow * window = [self window];
    NSSize auSize = [mAudioUnitView bounds].size;
    NSSize containerSize = [mContainerView bounds].size;
    if (!NSEqualSizes(auSize, containerSize))
    {
        float deltaWidth = containerSize.width - auSize.width;
        float deltaHeight = containerSize.height - auSize.height;
        
        NSRect windowFrame = [window frame];
        windowFrame.size.width -= deltaWidth;
        windowFrame.size.height -= deltaHeight;
        windowFrame.origin.y += deltaHeight;
        [window setFrame: windowFrame display: YES];
    }
}

- (void) setAudioUnitView: (NSView *) view;
{
    if (mAudioUnitView != nil)
    {
        [mAudioUnitView removeFromSuperview];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: nil
                                                      object: mAudioUnitView];
        [mAudioUnitView release];
        mAudioUnitView == nil;
    }
    
    if (view == nil)
    {
        view = [mNoEffectView retain];
    }
    
    mAudioUnitView = [view retain];
    NSWindow * window = [self window];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(auViewDidChange:)
                                                 name: nil
                                               object: mAudioUnitView];
    NSSize auSize = [mAudioUnitView bounds].size;
    NSSize containerSize = [mContainerView bounds].size;
    
    float deltaWidth = containerSize.width - auSize.width;
    float deltaHeight = containerSize.height - auSize.height;
    
    NSRect oldFrameRect = [window frame];
    NSRect newFrameRect = oldFrameRect;
    newFrameRect.size.width -= deltaWidth;
    newFrameRect.size.height -= deltaHeight;
    newFrameRect.origin.y += deltaHeight;

    unsigned mask = [mAudioUnitView autoresizingMask];
    BOOL widthSizable = ((mask & NSViewWidthSizable) != 0);
    BOOL heightSizable = ((mask & NSViewHeightSizable) != 0);
    NSSize minSize;
    NSSize maxSize;
    if (widthSizable)
    {
        minSize.width = newFrameRect.size.width;
        maxSize.width = FLT_MAX;
    }
    else if (!widthSizable)
    {
        minSize.width = newFrameRect.size.width;
        maxSize.width = newFrameRect.size.width;
    }
    
    if (heightSizable)
    {
        minSize.height = newFrameRect.size.height;
        maxSize.height = FLT_MAX;
    }
    else if (!heightSizable)
    {
        minSize.height = newFrameRect.size.height;
        maxSize.height = newFrameRect.size.height;
    }
    [window setMinSize: minSize];
    [window setMaxSize: maxSize];
    if (!heightSizable && !widthSizable)
    {
        [window setShowsResizeIndicator: NO];
    }
    else
    {
        [window setShowsResizeIndicator: YES];
    }
	
    BOOL animate = !NSEqualRects(oldFrameRect, newFrameRect);
    if (animate)
    {
        NSTimeInterval resizeTime = [window animationResizeTime: newFrameRect];
        [NSTimer scheduledTimerWithTimeInterval: resizeTime
                                         target: self
                                       selector: @selector(windowResizeFinished:)
                                       userInfo: nil
                                        repeats: NO];
        
        [window setFrame: newFrameRect display: YES animate: YES];
    }
    else
    {
        [window setFrame: newFrameRect display: YES animate: NO];
        [mContainerView addSubview: mAudioUnitView];
    }
}

- (void) windowResizeFinished: (NSTimer*) theTimer;
{
    [mContainerView addSubview: mAudioUnitView];
}

@end
