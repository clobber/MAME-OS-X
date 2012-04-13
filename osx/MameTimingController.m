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

#import "MameTimingController.h"
#import "MameController.h"
#include "uiinput.h"
#include <mach/mach_time.h>
#import "JRLog.h"

#define OSX_LOG_TIMING 0

#if OSX_LOG_TIMING
typedef struct
{
    char code;
    mame_time emutime;
    mame_time start_realtime;
    mame_time end_realtime;
    int throttle_count;
    double game_speed_percent;
    double frames_per_second;
    int frame_skip_level;
    int frame_skip_counter;
    int frame_skip_adjust;
} MameTimingStats;

#define NUM_STATS 100000
static MameTimingStats sTimingStats[NUM_STATS];
static uint32_t sTimingStatsIndex = 0;

static void update_stats(char code, mame_time emutime, mame_time start_realtime,
                         mame_time end_realtime, int throttleCount,
                         int frameSkipLevel, int frameSkipCounter,
                         int frameSkipAdjust);
static void dump_stats(void);

#endif

#define FRAMESKIP_LEVELS 12

// frameskipping tables
static const int sSkipTable[FRAMESKIP_LEVELS][FRAMESKIP_LEVELS] =
{
    { 0,0,0,0,0,0,0,0,0,0,0,0 },
    { 0,0,0,0,0,0,0,0,0,0,0,1 },
    { 0,0,0,0,0,1,0,0,0,0,0,1 },
    { 0,0,0,1,0,0,0,1,0,0,0,1 },
    { 0,0,1,0,0,1,0,0,1,0,0,1 },
    { 0,1,0,0,1,0,1,0,0,1,0,1 },
    { 0,1,0,1,0,1,0,1,0,1,0,1 },
    { 0,1,0,1,1,0,1,0,1,1,0,1 },
    { 0,1,1,0,1,1,0,1,1,0,1,1 },
    { 0,1,1,1,0,1,1,1,0,1,1,1 },
    { 0,1,1,1,1,1,0,1,1,1,1,1 },
    { 0,1,1,1,1,1,1,1,1,1,1,1 }
};

// For in-class use, so there is no Obj-C message passing overhead
static inline cycles_t osd_cycles_internal()
{
    return mach_absolute_time();
}

@interface MameTimingController (Private)

- (void) updateFps: (attotime) emutime;

- (void) checkOsdInputs;

@end

@implementation MameTimingController

- (id) init
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mThrottled = YES;
    mAutoFrameSkip = YES;
    
    return self;
}

- (void) osd_init: (running_machine*) machine;
{
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    mCyclesPerSecond = 1000000000LL *
        ((uint64_t)info.denom) / ((uint64_t)info.numer);
    JRLogDebug(@"cycles/second = %u/%u = %lld\n", info.denom, info.numer,
               mCyclesPerSecond);

    mThrottleLastCycles = 0;
    mFrameSkipCounter = 0;
    mFrameSkipLevel = 0;
    mFramesDisplayed = 0;
    mFramesRendered = 0;
    mFrameStartTime = 0;
	
	mMachine = machine;
}

- (osd_ticks_t) osd_ticks;
{
    return osd_cycles_internal();
}

- (osd_ticks_t) osd_ticks_per_second;
{
    return mCyclesPerSecond;
}

- (osd_ticks_t) osd_profiling_ticks;
{
    return mach_absolute_time();
}

- (int) osd_update: (attotime) emutime;
{
    [self updateThrottle: emutime];
    [self updateFps: emutime];
    [self updateAutoFrameSkip];
    [self checkOsdInputs];
    return [self skipFrame];
}

//=========================================================== 
//  throttled 
//=========================================================== 
- (BOOL) throttled
{
    return mThrottled;
}

- (void) setThrottled: (BOOL) flag
{
    mThrottled = flag;
}

- (BOOL) autoFrameSkip;
{
    return mAutoFrameSkip;
}

- (void) setAutoFrameSkip: (BOOL) autoFrameSkip;
{
    mAutoFrameSkip = autoFrameSkip;
}

- (void) updateThrottle: (attotime) emutime;
{
#if 0
#if OSX_LOG_TIMING
    char code = 'U';
    attotime start_realtime = mThrottleRealtime;
#endif

    int paused = mame_is_paused(Machine);
    if (paused)
    {
#if OSX_LOG_TIMING
        code = 'P';
#endif
        mThrottleRealtime = mThrottleEmutime = attotime_sub_subseconds(emutime, MAX_SUBSECONDS / Machine->screen[0].refresh);
    }
    
    // if time moved backwards (reset), or if it's been more than 1 second in emulated time, resync
    if (attotime_compare(emutime, mThrottleEmutime) < 0 || sub_mame_times(emutime, mThrottleEmutime).seconds > 0)
    {
#if OSX_LOG_TIMING
        code = 'B';
#endif
        goto resync;
    }
    
    cycles_t cyclesPerSecond = mCyclesPerSecond;
    cycles_t diffCycles = osd_cycles_internal() - mThrottleLastCycles;
    mThrottleLastCycles += diffCycles;
    // NSLog(@"diff: %llu, last: %llu", diffCycles, mThrottleLastCycles);
    if (diffCycles > cyclesPerSecond)
    {
        JRLogDebug(@"More than 1 sec, diff: %qi, cps: %qi", diffCycles, cyclesPerSecond);
        // Resync
#if OSX_LOG_TIMING
        code = '1';
#endif
        goto resync;
    }
    
    subseconds_t subsecsPerCycle = MAX_SUBSECONDS / cyclesPerSecond;
    mThrottleRealtime = attotime_add_subseconds(mThrottleRealtime, diffCycles * subsecsPerCycle);
    mThrottleEmutime = emutime;
    
    // if we're behind, just sync
    if (attotime_compare(mThrottleEmutime, mThrottleRealtime) <= 0)
    {
#if OSX_LOG_TIMING
        code = 'S';
#endif
        goto resync;
    }
    
    mame_time timeTilTarget = attotime_sub(mThrottleEmutime, mThrottleRealtime);
    cycles_t cyclesTilTarget = timeTilTarget.subseconds / subsecsPerCycle;
    cycles_t target = mThrottleLastCycles + cyclesTilTarget;
    
    cycles_t curr = osd_cycles_internal();
    int count = 0;
#if 1
    if (mThrottled)
    {
        mach_wait_until(mThrottleLastCycles + cyclesTilTarget*95/100);
        for (curr = osd_cycles_internal(); curr - target < 0; curr = osd_cycles_internal())
        {
            count++;
        }
    }
#endif
    
    // update realtime
    diffCycles = osd_cycles_internal() - mThrottleLastCycles;
    mThrottleLastCycles += diffCycles;
    mThrottleRealtime = attotime_add_subseconds(mThrottleRealtime, diffCycles * subsecsPerCycle);
#if OSX_LOG_TIMING
    update_stats(code, emutime, start_realtime, mThrottleRealtime, count,
                 mFrameSkipLevel, mFrameSkipCounter, mFrameSkipAdjustment);
#endif
    
    return;
    
resync:
        mThrottleRealtime = mThrottleEmutime = emutime;
#if OSX_LOG_TIMING
        update_stats(code, emutime, start_realtime, mThrottleRealtime, -1,
                     mFrameSkipLevel, mFrameSkipCounter, mFrameSkipAdjustment);
#endif
    return;
#endif
}

- (void) updateAutoFrameSkip;
{
#if 0
    int frameSkipCounter = mFrameSkipCounter;
	mFrameSkipCounter = (mFrameSkipCounter + 1) % FRAMESKIP_LEVELS;

    // Only update at begining of sequence
    if (!mAutoFrameSkip || (frameSkipCounter != 0))
        return;
    
	// skip if paused
	if (mame_is_paused(Machine))
		return;
    
	// don't adjust frameskip if we're paused or if the debugger was
	// visible this cycle or if we haven't run yet
	if (cpu_getcurrentframe() > 2 * FRAMESKIP_LEVELS)
	{
		const performance_info *performance = mame_get_performance_info();
        
		// if we're too fast, attempt to increase the frameskip
		if (performance->game_speed_percent >= 99.5)
		{
			mFrameSkipAdjustment++;
            
			// but only after 3 consecutive frames where we are too fast
			if (mFrameSkipAdjustment >= 3)
			{
				mFrameSkipAdjustment = 0;
				if (mFrameSkipLevel > 0)
                    mFrameSkipLevel--;
			}
		}
        
		// if we're too slow, attempt to increase the frameskip
		else
		{
			// if below 80% speed, be more aggressive
			if (performance->game_speed_percent < 80)
				mFrameSkipAdjustment -= (90 - performance->game_speed_percent) / 5;
            
			// if we're close, only force it up to frameskip 8
			else if (mFrameSkipLevel < 8)
				mFrameSkipAdjustment--;
            
			// perform the adjustment
			while (mFrameSkipAdjustment <= -2)
			{
				mFrameSkipAdjustment += 2;
				if (mFrameSkipLevel < FRAMESKIP_LEVELS - 1)
					mFrameSkipLevel++;
			}
		}
	}
#endif
}

- (int) skipFrame;
{
    return sSkipTable[mFrameSkipLevel][mFrameSkipCounter];
}

- (void) gameFinished;
{
#if OSX_LOG_TIMING
    dump_stats();
#endif
}

- (cycles_t) fpsCycles;
{
    return mFrameEndTime - mFrameStartTime;
}

- (uint64_t) framesDisplayed;
{
    return mFramesDisplayed;
}

- (uint64_t) framesRendered;
{
    return mFramesRendered;
}

- (void) frameWasDisplayed;
{
    if (mFrameStartTime != 0)
        mFramesDisplayed++;
}

- (void) frameWasRendered;
{
    if (mFrameStartTime != 0)
        mFramesRendered++;
}

- (double) fpsDisplayed;
{
    return (double) mCyclesPerSecond / [self fpsCycles] * mFramesDisplayed;
}

- (double) fpsRendered;
{
    return (double) mCyclesPerSecond / [self fpsCycles] * mFramesRendered;
}

@end

@implementation MameTimingController (Private)

- (void) updateFps: (attotime) emutime;
{
    cycles_t currentCycles = osd_cycles_internal();
    if (mFrameStartTime == 0)
    {
		// start the timer going 1 second into the game
		if (emutime.seconds > 1)
            mFrameStartTime = currentCycles;
    }
    else
    {
        mFrameEndTime = currentCycles;
    }
}

- (void) checkOsdInputs;
{
    BOOL resetFrameCounters = NO;

	// increment frameskip?
	if (ui_input_pressed(*(mMachine), IPT_UI_FRAMESKIP_INC))
	{
		// if autoframeskip, disable auto and go to 0
		if (mAutoFrameSkip)
		{
			mAutoFrameSkip = NO;
			mFrameSkipLevel = 0;
		}
        
		// wrap from maximum to auto
		else if (mFrameSkipLevel == FRAMESKIP_LEVELS - 1)
		{
			mFrameSkipLevel = 0;
			mAutoFrameSkip = YES;
		}
        
		// else just increment
		else
			mFrameSkipLevel++;
        
		// display the FPS counter for 2 seconds
		ui_show_fps_temp(2.0);
        
        resetFrameCounters = YES;
	}

	// decrement frameskip?
	if (ui_input_pressed(*(mMachine),IPT_UI_FRAMESKIP_DEC))
	{
		// if autoframeskip, disable auto and go to max
		if (mAutoFrameSkip)
		{
			mAutoFrameSkip = NO;
			mFrameSkipLevel = FRAMESKIP_LEVELS-1;
		}
        
		// wrap from 0 to auto
		else if (mFrameSkipLevel == 0)
			mAutoFrameSkip = YES;
        
		// else just decrement
		else
			mFrameSkipLevel--;
        
		// display the FPS counter for 2 seconds
		ui_show_fps_temp(2.0);
        
        resetFrameCounters = YES;
	}

	// toggle throttle?
	if (ui_input_pressed(*(mMachine), IPT_UI_THROTTLE))
	{
		[self setThrottled: !mThrottled];
        
        resetFrameCounters = YES;
    }
    
    if (resetFrameCounters)
    {
        mFrameStartTime = 0;
        mFramesDisplayed = 0;
        mFramesRendered = 0;
    }
}

@end;

#if OSX_LOG_TIMING

static void update_stats(char code, mame_time emutime, mame_time start_realtime,
                         mame_time end_realtime, int throttle_count,
                         int frameSkipLevel, int frameSkipCounter,
                         int frameSkipAdjust)
{
    if (sTimingStatsIndex >= NUM_STATS)
        return;
    
    const performance_info * performance = mame_get_performance_info();
    MameTimingStats * stats = &sTimingStats[sTimingStatsIndex];
    stats->code = code;
    stats->emutime = emutime;
    stats->start_realtime = start_realtime;
    stats->end_realtime = end_realtime;
    stats->throttle_count = throttle_count;
    stats->game_speed_percent = performance->game_speed_percent;
    stats->frames_per_second = performance->frames_per_second;
    stats->frame_skip_level = frameSkipLevel;
    stats->frame_skip_counter = frameSkipCounter;
    stats->frame_skip_adjust = frameSkipAdjust;
    sTimingStatsIndex++;
}

static void dump_stats(void)
{
    FILE * file = fopen("/tmp/timing_stats.txt", "w");
    uint32_t i;
    for (i = 0; i < sTimingStatsIndex; i++)
    {
        MameTimingStats * stats = &sTimingStats[i];
        /* subseconds are tracked in attosecond (10^-18) increments */
        fprintf(file, "%5u %c %d.%018lld %d.%018lld %d.%018lld %5ld "
                "%5.1f%% %4.1f "
                "Skip: %2d, %2d = %d %d\n",
                i, stats->code,
                stats->emutime.seconds, stats->emutime.subseconds,
                stats->start_realtime.seconds, stats->start_realtime.subseconds,
                stats->end_realtime.seconds, stats->end_realtime.subseconds,
                stats->throttle_count,
                stats->game_speed_percent, stats->frames_per_second,
                stats->frame_skip_level, stats->frame_skip_counter,
                sSkipTable[stats->frame_skip_level][stats->frame_skip_counter],
                stats->frame_skip_adjust);
    }
    fclose(file);
}

#endif

