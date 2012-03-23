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
#include "osdepend.h"

// DLD Hack
typedef osd_ticks_t cycles_t;

@interface MameTimingController : NSObject
{
    BOOL mThrottled;
    BOOL mAutoFrameSkip;
    
    cycles_t mCyclesPerSecond;

    cycles_t mThrottleLastCycles;
    attotime mThrottleRealtime;
    attotime mThrottleEmutime;
    
    int mFrameSkipCounter;
    int mFrameSkipLevel;
    int mFrameSkipAdjustment;

    uint64_t mFramesDisplayed;
    uint64_t mFramesRendered;
    cycles_t mFrameStartTime;
    cycles_t mFrameEndTime;
	
	running_machine * mMachine;
}

- (void) osd_init: (running_machine*) machine;

- (osd_ticks_t) osd_ticks;

- (osd_ticks_t) osd_ticks_per_second;

- (osd_ticks_t) osd_profiling_ticks;

- (int) osd_update: (attotime) emutime;

- (BOOL) throttled;
- (void) setThrottled: (BOOL) flag;

- (BOOL) autoFrameSkip;
- (void) setAutoFrameSkip: (BOOL) autoFrameSkip;

- (void) updateThrottle: (attotime) emutime;

- (void) updateAutoFrameSkip;

- (int) skipFrame;

- (void) gameFinished;

- (cycles_t) fpsCycles;

- (uint64_t) framesDisplayed;

- (uint64_t) framesRendered;

- (void) frameWasDisplayed;

- (void) frameWasRendered;

- (double) fpsDisplayed;

- (double) fpsRendered;

@end
