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

#import "MameConfiguration.h"
#import "MameController.h"
#import "MameFileManager.h"
#include <mach/mach_host.h>
#include <mach/host_info.h>

@interface MameConfiguration (Private)

- (void) setStringOption: (NSString *) stringValue
                withName: (const char *) name;

- (NSString *) getStringOption: (const char *) name;

- (void) setBoolOption: (BOOL) boolValue
              withName: (const char *) name;

- (void) setIntOption: (int) intValue
             withName: (const char *) name;

- (void) setFloatOption: (float) floatValue
               withName: (const char *) name;

@end

@implementation MameConfiguration

static MameConfiguration * sDefaultConfiguration = nil;

+ (MameConfiguration *) defaultConfiguration;
{
    if (sDefaultConfiguration == nil)
        sDefaultConfiguration = [[self alloc] init];
    return sDefaultConfiguration;
}

- (id) init
{
    self = [super init];
    if (self == nil)
        return nil;

    //mCoreOptions = mame_options_init(NULL);
    mCoreOptions = new emu_options();

    return self;
}

- (void)dealloc
{
    //delete mCoreOptions;

    [super dealloc];
}

- (emu_options *) coreOptions;
{
    return mCoreOptions;
}

#pragma mark -
#pragma mark Directories and paths

- (void) setRomPath: (NSString *) romPath;
{
    [self setStringOption: romPath withName: OPTION_MEDIAPATH];
}

- (void) setSamplePath: (NSString *) samplePath;
{
    [self setStringOption: samplePath withName: OPTION_SAMPLEPATH];
}

- (void) setArtworkPath: (NSString *) artworkPath;
{
    [self setStringOption: artworkPath withName: OPTION_ARTPATH];
}

- (void) setDiffDirectory: (NSString *) diffDirectory;
{
    [self setStringOption: diffDirectory withName: OPTION_DIFF_DIRECTORY];
}

- (void) setNvramDirectory: (NSString *) nvramDirectory;
{
    [self setStringOption: nvramDirectory withName: OPTION_NVRAM_DIRECTORY];
}

- (void) setConfigDirectory: (NSString *) configDirectory;
{
    [self setStringOption: configDirectory withName: OPTION_CFG_DIRECTORY];
}

- (void) setInputDirectory: (NSString *) inputDirectory;
{
    [self setStringOption: inputDirectory withName: OPTION_INPUT_DIRECTORY];
}

- (void) setStateDirectory: (NSString *) stateDirectory;
{
    [self setStringOption: stateDirectory withName: OPTION_STATE_DIRECTORY];
}

- (void) setMemcardDirectory: (NSString *) memcardDirectory;
{
    [self setStringOption: memcardDirectory withName: OPTION_MEMCARD_DIRECTORY];
}

- (void) setSnapshotDirectory: (NSString *) snapshotDirectory;
{
    [self setStringOption: snapshotDirectory withName: OPTION_SNAPSHOT_DIRECTORY];
}

- (void) setCtrlrPath: (NSString *) ctlrPath;
{
    [self setStringOption: ctlrPath withName: OPTION_CTRLRPATH];
}

- (void) setCommentDirectory: (NSString *) commentDirectory;
{
    [self setStringOption: commentDirectory withName: OPTION_COMMENT_DIRECTORY];
}

- (void) setFontPath: (NSString *) fontPath;
{
    [self setStringOption: fontPath withName: OPTION_FONTPATH];
}

- (NSString *) fontPath;
{
    return [self getStringOption: OPTION_FONTPATH];
}

#pragma mark -
#pragma mark Inputs

- (void) setMouseEnabled: (BOOL) mouseEnabled;
{
    [self setBoolOption: mouseEnabled withName: OPTION_MOUSE];
}

- (void) setJoystickEnabled: (BOOL) mouseEnabled;
{
    [self setBoolOption: mouseEnabled withName: OPTION_JOYSTICK];
}

- (void) setMultiKeyboard: (BOOL) multiKeyboard;
{
    [self setBoolOption: multiKeyboard withName: OPTION_MULTIKEYBOARD];
}

- (void) setMultiMouse: (BOOL) multiMouse;
{
    [self setBoolOption: multiMouse withName: OPTION_MULTIMOUSE];
}

- (void) setJoystickDeadzone: (float) deadzone;
{
    [self setFloatOption: deadzone withName: OPTION_JOYSTICK_DEADZONE];
}

- (void) setJoystickSaturation: (float) saturation;
{
    [self setFloatOption: saturation withName: OPTION_JOYSTICK_SATURATION];
}

#pragma mark -

- (void) setGameName: (NSString *) gameName;
{
    [self setStringOption: gameName withName: OPTION_SYSTEMNAME];
}

#ifdef MAME_DEBUG
- (void) setMameDebug: (BOOL) mameDebug;
{
    [self setBoolOption: mameDebug withName: OPTION_DEBUG];
}
#endif

- (void) setCheat: (BOOL) cheat;
{
    [self setBoolOption: cheat withName: OPTION_CHEAT];
}

- (void) setCheatFile: (NSString *) cheatFile;
{
    [self setStringOption: cheatFile withName: OPTION_CHEATPATH];
}

#pragma mark -
#pragma mark Messages

- (void) setSkipDisclaimer: (BOOL) skipDisclaimer;
{
#if 0 // Todo: Fix
    options.skip_disclaimer = skipDisclaimer;
#endif
}

- (void) setSkipGameInfo: (BOOL) skipGameInfo;
{
    [self setBoolOption: skipGameInfo withName: OPTION_SKIP_GAMEINFO];
}

- (void) setSkipWarnings: (BOOL) skipWarnings;
{
#if 0 // Todo: fix
    options.skip_warnings = skipWarnings;
#endif
}

#pragma mark -
#pragma mark Sound

- (void) setSampleRate: (int) sampleRate;
{
    [self setIntOption: sampleRate withName: OPTION_SAMPLERATE];
}

- (void) setUseSamples: (BOOL) useSamples;
{
    [self setBoolOption: useSamples withName: OPTION_SAMPLES];
}

#pragma mark -
#pragma mark Graphics

- (void) setBrightness: (float) brightness;
{
    [self setFloatOption: brightness withName: OPTION_BRIGHTNESS];
}

- (void) setContrast: (float) contrast;
{
    [self setFloatOption: contrast withName: OPTION_CONTRAST];
}

- (void) setGamma: (float) gamma;
{
    [self setFloatOption: gamma withName: OPTION_GAMMA];
}

- (void) setPauseBrightness: (float) pauseBrightness;
{
    [self setFloatOption: pauseBrightness withName: OPTION_PAUSE_BRIGHTNESS];
}

#pragma mark -
#pragma mark Vector

- (void) setBeam: (float) beam;
{
    [self setFloatOption: beam withName: OPTION_BEAM];
}

- (void) setAntialias: (BOOL) antialias;
{
    [self setBoolOption: antialias withName: OPTION_ANTIALIAS];
}

- (void) setVectorFlicker: (float) vectorFlicker;
{
    [self setFloatOption: vectorFlicker withName: OPTION_FLICKER];
}

#pragma mark -
#pragma mark Performance

- (void) setAutoFrameSkip: (BOOL) autoFrameSkip;
{
    [self setBoolOption: autoFrameSkip withName: OPTION_AUTOFRAMESKIP];
}

- (void) setThrottle: (BOOL) throttle;
{
    [self setBoolOption: throttle withName: OPTION_THROTTLE];
}

- (void) setRefreshSpeed: (BOOL) refreshSpeed;
{
    [self setBoolOption: refreshSpeed withName: OPTION_REFRESHSPEED];
}

#pragma mark -

//=========================================================== 
//  saveGame 
//=========================================================== 
- (NSString *) saveGame
{
    return [self getStringOption: OPTION_STATE];
}

- (void) setSaveGame: (NSString *) newSaveGame
{
    [self setStringOption: newSaveGame withName: OPTION_STATE];
}

- (void) setAutoSave: (BOOL) autoSave;
{
    [self setBoolOption: autoSave withName: OPTION_AUTOSAVE];
}

//=========================================================== 
//  bios 
//=========================================================== 
- (NSString *) bios
{
    return [self getStringOption: OPTION_BIOS];
}

- (void) setBios: (NSString *) newBios
{
    [self setStringOption: newBios withName: OPTION_BIOS];
}

@end

@implementation MameConfiguration (Private)


- (void) setStringOption: (NSString *) stringValue
                withName: (const char *) name;
{
    if (stringValue == nil)
        return;
    //options_set_string(mCoreOptions, name, [stringValue UTF8String], OPTION_PRIORITY_CMDLINE);
    astring err;
    mCoreOptions->set_value(name, [stringValue UTF8String], OPTION_PRIORITY_CMDLINE, err);
}

- (NSString *) getStringOption: (const char *) name;
{
    //const char * value = options_get_string(mCoreOptions, name);
    const char * value = mCoreOptions->value(name);
    return [NSString stringWithUTF8String: value];
}

- (void) setBoolOption: (BOOL) boolValue
              withName: (const char *) name;
{
    //options_set_bool(mCoreOptions, name, boolValue, OPTION_PRIORITY_CMDLINE);
    astring err;
    mCoreOptions->set_value(name, boolValue, OPTION_PRIORITY_CMDLINE, err);
}

- (void) setIntOption: (int) intValue
             withName: (const char *) name;
{
    //options_set_int(mCoreOptions, name, intValue, OPTION_PRIORITY_CMDLINE);
    astring err;
    mCoreOptions->set_value(name, intValue, OPTION_PRIORITY_CMDLINE, err);
}

- (void) setFloatOption: (float) floatvalue
               withName: (const char *) name;
{
    //options_set_float(mCoreOptions, name, floatvalue, OPTION_PRIORITY_CMDLINE);
    astring err;
    mCoreOptions->set_value(name, floatvalue, OPTION_PRIORITY_CMDLINE, err);
}

@end
