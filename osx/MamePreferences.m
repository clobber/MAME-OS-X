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

#import "MamePreferences.h"
#import "MameConfiguration.h"
#import "MameVersion.h"
#include <mach/mach_host.h>
#include <mach/host_info.h>

@interface MamePreferences (Private)

- (BOOL) hasMultipleCPUs;
- (void) initializeDefaultPaths: (NSMutableDictionary *) defaultValues;

@end


static MamePreferences * sInstance;

NSString * MameJRLogLevelKey = @"JRLogLevel";
NSString * MameVersionUrlKey = @"VersionUrl";
NSString * MameCheckUpdatesAtStartupKey = @"CheckUpdatesAtStartup";
NSString * MameGameKey = @"Game";
NSString * MameSleepAtExitKey = @"SleepAtExit";
NSString * MamePreviousGamesKey = @"PreviousGames";

NSString * MameWindowedZoomLevelKey = @"WindowedZoomLevel";
NSString * MameZoomLevelActual = @"Actual";
NSString * MameZoomLevelDouble = @"Double";
NSString * MameZoomLevelMaximumIntegral = @"MaximumIntegral";
NSString * MameZoomLevelMaximum = @"Maximum";

NSString * MameFullScreenKey = @"FullScreen";
NSString * MameSwitchResolutionsKey = @"SwitchResolutions";
NSString * MameFullScreenZoomLevelKey = @"FullScreenZoomLevel";
NSString * MameFullScreenMaximumValue = @"Maximum";
NSString * MameFullScreenIntegralValue = @"Integral";
NSString * MameFullScreenIndependentIntegralValue = @"IndependentIntegral";
NSString * MameFullScreenStretchValue = @"Stretch";

NSString * MameFrameRenderingKey = @"FrameRendering";
NSString * MameRenderFrameInOpenGLValue = @"OpenGL";
NSString * MameRenderFrameInCoreImageValue = @"CoreImage";
NSString * MameFrameRenderingDefaultValue = @"Auto";

NSString * MameRenderingThreadKey = @"RenderingThread";
NSString * MameRenderInCoreVideoThreadValue = @"CoreVideo";
NSString * MameRenderInMameThreadValue = @"MameThread";
NSString * MameRenderingThreadDefaultValue = @"Auto";

NSString * MameSyncToRefreshKey = @"SyncToRefresh";
NSString * MameSoundEnabledKey = @"SoundEnabled";
NSString * MameClearToRedKey = @"ClearToRed";
NSString * MameLinearFilterKey = @"LinearFilter";
NSString * MameVisualEffectKey = @"VisualEffect";
NSString * MameSmoothFontKey = @"SmoothFont";
NSString * MameGrabMouseKey = @"GrabMouse";
NSString * MameAuditAtStartupKey = @"AuditAtStartup";

NSString * MameRomPath = @"RomPath";
NSString * MameDiskImagePath = @"DiskImagePath";
NSString * MameSamplePath = @"SamplePath";
NSString * MameConfigPath = @"ConfigPath";
NSString * MameNvramPath = @"NvramPath";
NSString * MameMemcardPath = @"MemcardPath";
NSString * MameInputPath = @"InputPath";
NSString * MameStatePath = @"StatePath";
NSString * MameArtworkPath = @"ArtworkPath";
NSString * MameSnapshotPath = @"SnapshotPath";
NSString * MameDiffPath = @"DiffPath";
NSString * MameCtrlrPath = @"CtrlrPath";
NSString * MameCommentPath = @"CommentPath";
NSString * MameFontPath = @"FontPath";
NSString * MameEffectPath = @"EffectPath";

NSString * MameMouseKey = @"Mouse";
NSString * MameJoystickKey = @"Joystick";
NSString * MameMultiKeyboardKey = @"MultiKeyboard";
NSString * MameMultiMouseKey = @"MultiMouse";
NSString * MameJoystickDeadzoneKey = @"JoystickDeadzone";
NSString * MameJoystickSaturationKey = @"JoystickSaturation";

#ifdef MAME_DEBUG
NSString * MameDebugKey = @"MameDebug";
#endif
NSString * MameCheatKey = @"Cheat";
NSString * MameSkipDisclaimerKey = @"SkipDisclaimer";
NSString * MameSkipGameInfoKey = @"SkipGameInfo";
NSString * MameSkipWarningsKey = @"SkipWarnings";

NSString * MameSampleRateKey = @"SampleRate";
NSString * MameUseSamplesKey = @"UseSamples";

NSString * MameKeepAspectKey = @"KeepAspect";

NSString * MameBrightnessKey = @"Brightness";
NSString * MameContrastKey = @"Contrast";
NSString * MameGammaKey = @"Gamma";
NSString * MamePauseBrightnessKey = @"PauseBrightness";

NSString * MameBeamWidthKey = @"BeamWidth";
NSString * MameVectorFlickerKey = @"VectorFlicker";
NSString * MameAntialiasBeamKey = @"AntialiasBeam";

NSString * MameThrottledKey = @"Throttled";
NSString * MameAutoFrameSkipKey = @"AutoFrameSkip";
NSString * MameRefreshSpeedKey = @"RefreshSpeed";

NSString * MameSaveGameKey = @"SaveGame";
NSString * MameAutosaveKey = @"AutoSave";
NSString * MameBiosKey = @"Bios";

NSString * MameGameSortDescriptorsKey = @"GameSortDescriptors";
NSString * MameGameFilterIndexKey = @"GameFilterIndex";
NSString * MameBackgroundUpdateDebugKey = @"BackgroundUpdateDebug";
NSString * MameForceUpdateGameListKey = @"ForceUpdateGameList";
NSString * MameDeleteOldGamesKey = @"DeleteOldGames";
NSString * MameLogAllToConsoleKey = @"LogAllToConsole";

NSString * MamePreferencesVersionKey = @"PreferencesVersion";

@implementation MamePreferences

#pragma mark Init and dealloc

+ (MamePreferences *) standardPreferences;
{
    if (sInstance == nil)
        sInstance = [[MamePreferences alloc] init];
    
    return sInstance;
}

- (id) init;
{
    return [self initWithUserDefaults: [NSUserDefaults standardUserDefaults]];
}

- (id) initWithUserDefaults: (NSUserDefaults *) userDefaults;
{
    self = [super init];
    if (self == nil)
        return nil;
   
    mDefaults = [userDefaults retain];

    return self;
}

- (void) dealloc
{
    [mDefaults release];
    [super dealloc];
}

#pragma mark -
#pragma mark User defaults

- (void) registerDefaults;
{
    NSMutableDictionary * defaultValues = [NSMutableDictionary dictionary];
    NSNumber * yes = [NSNumber numberWithBool: YES];
    NSNumber * no = [NSNumber numberWithBool: NO];
    
    [defaultValues setObject: @"WARN"
                      forKey: MameJRLogLevelKey];
    
    [defaultValues setObject: @"http://mameosx.sourceforge.net/version.plist"
                      forKey: MameVersionUrlKey];
    
    [defaultValues setObject: yes
                      forKey: MameCheckUpdatesAtStartupKey];
    
    [defaultValues setObject: yes
                      forKey: MameWindowedZoomLevelKey];
    
    [defaultValues setObject: MameZoomLevelDouble
                      forKey: MameWindowedZoomLevelKey];
    
    [defaultValues setObject: no
                      forKey: MameFullScreenKey];
    
    [defaultValues setObject: no
                      forKey: MameSwitchResolutionsKey];
    
    [defaultValues setObject: MameFullScreenMaximumValue
                      forKey: MameFullScreenZoomLevelKey];
    
    [self initializeDefaultPaths: defaultValues];
    
    [defaultValues setObject: yes
                      forKey: MameSyncToRefreshKey];
    
    [defaultValues setObject: yes
                      forKey: MameSoundEnabledKey];
    

    [defaultValues setObject: MameFrameRenderingDefaultValue
                      forKey: MameFrameRenderingKey];
    
    [defaultValues setObject: MameRenderingThreadDefaultValue
                      forKey: MameRenderingThreadKey];
        
    [defaultValues setObject: no
                      forKey: MameClearToRedKey];

    [defaultValues setObject: yes
                      forKey: MameLinearFilterKey];
    
    [defaultValues setObject: yes
                      forKey: MameSmoothFontKey];
    
    [defaultValues setObject: no
                      forKey: MameGrabMouseKey];
    
    [defaultValues setObject: no forKey: MameAuditAtStartupKey];
    
#ifdef MAME_DEBUG
    [defaultValues setObject: no
                      forKey: MameDebugKey];
#endif
    [defaultValues setObject: no
                      forKey: MameCheatKey];
    
    [defaultValues setObject: yes forKey: MameMouseKey];
    [defaultValues setObject: yes forKey: MameJoystickKey];
    [defaultValues setObject: no forKey: MameMultiKeyboardKey];
    [defaultValues setObject: no forKey: MameMultiMouseKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 0.3f]
                      forKey: MameJoystickDeadzoneKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 0.85f]
                      forKey: MameJoystickSaturationKey];
    
    [defaultValues setObject: no
                      forKey: MameSkipDisclaimerKey];
    [defaultValues setObject: no
                      forKey: MameSkipGameInfoKey];
    [defaultValues setObject: no
                      forKey: MameSkipWarningsKey];
    
    [defaultValues setObject: [NSNumber numberWithInt: 48000]
                      forKey: MameSampleRateKey];
    [defaultValues setObject: yes
                      forKey: MameUseSamplesKey];
    
    [defaultValues setObject: yes
                      forKey: MameKeepAspectKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 1.0f]
                      forKey: MameBrightnessKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 1.0f]
                      forKey: MameContrastKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 1.0f]
                      forKey: MameGammaKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 0.65f]
                      forKey: MamePauseBrightnessKey];
    
    [defaultValues setObject: [NSNumber numberWithFloat: 1.0f]
                      forKey: MameBeamWidthKey];
    [defaultValues setObject: [NSNumber numberWithFloat: 0.0f]
                      forKey: MameVectorFlickerKey];
    [defaultValues setObject: yes
                      forKey: MameAntialiasBeamKey];
    
    [defaultValues setObject: yes 
                      forKey: MameThrottledKey];
    [defaultValues setObject: yes
                      forKey: MameAutoFrameSkipKey];
    [defaultValues setObject: no
                      forKey: MameRefreshSpeedKey];

    [defaultValues setObject: no
                      forKey: MameAutosaveKey];
    [defaultValues setObject: @"default"
                      forKey: MameBiosKey];
    
    [defaultValues setObject: [NSNumber numberWithInt: 1]
                      forKey: MameGameFilterIndexKey];
    
    [defaultValues setObject: no
                      forKey: MameBackgroundUpdateDebugKey];

    [defaultValues setObject: no
                      forKey: MameForceUpdateGameListKey];
    
    [defaultValues setObject: [MameVersion isTiny]? no : yes
                      forKey: MameDeleteOldGamesKey];
    
    [defaultValues setObject: no forKey: MameLogAllToConsoleKey];

    [mDefaults registerDefaults: defaultValues];
}

- (void) synchronize;
{
    [mDefaults synchronize];
}

#pragma mark -
#pragma mark MAME OS X Options

- (NSString *) jrLogLevel;
{
    return [mDefaults stringForKey: MameJRLogLevelKey];
}

- (void) setJrLogLevel: (NSString *) jrLogLevel;
{
    [mDefaults setObject: jrLogLevel forKey: MameJRLogLevelKey];
}

- (NSString *) windowedZoomLevel;
{
    return [mDefaults stringForKey: MameWindowedZoomLevelKey];
}

- (void) setWindowedZoomLevel: (NSString *) windowedZoomLevel;
{
    [mDefaults setObject: windowedZoomLevel forKey: MameWindowedZoomLevelKey];
}

- (BOOL) fullScreen;
{
    return [mDefaults boolForKey: MameFullScreenKey];
}

- (void) setFullScreen: (BOOL) fullScreen;
{
    [mDefaults setBool: fullScreen forKey: MameFullScreenKey];
}

- (BOOL) switchResolutions;
{
    return [mDefaults boolForKey: MameSwitchResolutionsKey];
}

- (void) setSwitchResolutions: (BOOL) switchResolutions;
{
    [mDefaults setBool: switchResolutions forKey: MameSwitchResolutionsKey];
}

- (NSString *) fullScreenZoomLevel;
{
    return [mDefaults stringForKey: MameFullScreenZoomLevelKey];
}

- (void) setFullScreenZoomLevel: (NSString *) fullScreenZoomLevel;
{
    [mDefaults setObject: fullScreenZoomLevel forKey: MameFullScreenZoomLevelKey];
}

//=========================================================== 
//  syncToRefresh 
//=========================================================== 
- (BOOL) syncToRefresh;
{
    return [mDefaults boolForKey: MameSyncToRefreshKey];
}

- (void) setSyncToRefresh: (BOOL) flag;
{
    [mDefaults setBool: flag forKey:MameSyncToRefreshKey];
}

//=========================================================== 
//  soundEnabled 
//=========================================================== 
- (BOOL) soundEnabled;
{
    return [mDefaults boolForKey: MameSoundEnabledKey];
}

- (void) setSoundEnabled: (BOOL) flag;
{
    [mDefaults setBool: flag forKey: MameSoundEnabledKey];
}


- (NSString *) frameRendering;
{
    return [mDefaults stringForKey: MameFrameRenderingKey];
}

- (void) setFrameRendering: (NSString *) frameRendering;
{
    [mDefaults setObject: frameRendering forKey: MameFrameRenderingKey];
}

- (NSString *) renderingThread;
{
    return [mDefaults stringForKey: MameRenderingThreadKey];
}

- (void) setRenderingThread: (NSString *) renderingThread;
{
    [mDefaults setObject: renderingThread forKey: MameRenderingThreadKey];
}

//=========================================================== 
//  clearToRed 
//=========================================================== 
- (BOOL) clearToRed;
{
    return [mDefaults boolForKey: MameClearToRedKey];
}

- (void) setClearToRed: (BOOL) clearToRed;
{
    [mDefaults setBool: clearToRed forKey: MameClearToRedKey];
}

- (BOOL) linearFilter;
{
    return [mDefaults boolForKey: MameLinearFilterKey];
}

- (void) setLinearFilter: (BOOL) linearFilter;
{
    [mDefaults setBool: linearFilter forKey: MameLinearFilterKey];
}

- (NSString *) visualEffect;
{
    return [mDefaults stringForKey: MameVisualEffectKey];
}

- (void) seVisualEffect: (NSString *) visualEffect;
{
    [mDefaults setObject: visualEffect forKey: MameVisualEffectKey];
}

- (BOOL) smoothFont;
{
    return [mDefaults boolForKey: MameSmoothFontKey];
}

- (void) setSmoothFont: (BOOL) smoothFont;
{
    [mDefaults setBool: smoothFont forKey: MameSmoothFontKey];
}

- (BOOL) checkUpdatesAtStartup;
{
    return [mDefaults boolForKey: MameCheckUpdatesAtStartupKey];
}

- (BOOL) grabMouse;
{
    return [mDefaults boolForKey: MameGrabMouseKey];
}

- (void) setGrabMouse: (BOOL) grabMouse;
{
    [mDefaults setBool: grabMouse forKey: MameGrabMouseKey];
}

- (BOOL) auditAtStartup;
{
    return [mDefaults boolForKey: MameAuditAtStartupKey];
}

- (void) setAuditAtStartup: (BOOL) auditAtStartup;
{
    [mDefaults setBool: auditAtStartup forKey: MameAuditAtStartupKey];
}

#pragma mark -
#pragma mark Private MAME OS X Options

- (NSArray *) previousGames;
{
    return [mDefaults arrayForKey: MamePreviousGamesKey];
}

- (void) setPreviousGames: (NSArray *) previousGames;
{
    [mDefaults setObject: previousGames forKey: MamePreviousGamesKey];
}

- (NSString *) versionUrl;
{
    return [mDefaults stringForKey: MameVersionUrlKey];
}

- (NSString *) game;
{
    return [mDefaults stringForKey: MameGameKey];
}

- (BOOL) sleepAtExit;
{
    return [mDefaults boolForKey: MameSleepAtExitKey];
}

#pragma mark -
#pragma mark Directories and paths

- (NSString *) romPath;
{
    return [mDefaults stringForKey: MameRomPath];
}

- (NSString *) diskImagePath;
{
    return [mDefaults stringForKey: MameDiskImagePath];
}

- (NSString *) samplePath;
{
    return [mDefaults stringForKey: MameSamplePath];
}

- (NSString *) artworkPath;
{
    return [mDefaults stringForKey: MameArtworkPath];
}

- (NSString *) diffDirectory;
{
    return [mDefaults stringForKey: MameDiffPath];
}

- (NSString *) nvramDirectory;
{
    return [mDefaults stringForKey: MameNvramPath];
}

- (NSString *) configDirectory;
{
    return [mDefaults stringForKey: MameConfigPath];
}

- (NSString *) inputDirectory;
{
    return [mDefaults stringForKey: MameInputPath];
}

- (NSString *) stateDirectory;
{
    return [mDefaults stringForKey: MameStatePath];
}

- (NSString *) memcardDirectory;
{
    return [mDefaults stringForKey: MameMemcardPath];
}

- (NSString *) snapshotDirectory;
{
    return [mDefaults stringForKey: MameSnapshotPath];
}

- (NSString *) ctrlrPath;
{
    return [mDefaults stringForKey: MameCtrlrPath];
}

- (NSString *) commentDirectory;
{
    return [mDefaults stringForKey: MameCommentPath];
}

- (NSString *) fontPath;
{
    return [mDefaults stringForKey: MameFontPath];
}

- (NSString *) effectPath;
{
    return [mDefaults stringForKey: MameEffectPath];
}

#pragma mark -

#ifdef MAME_DEBUG
- (BOOL) mameDebug;
{
    return [mDefaults boolForKey: MameDebugKey];
}
#endif

- (BOOL) cheat;
{
    return [mDefaults boolForKey: MameCheatKey];
}

#pragma mark -
#pragma mark Inputs

- (BOOL) isMouseEnabled;
{
    return [mDefaults boolForKey: MameMouseKey];
}

- (void) setMouseEnabled: (BOOL) mouseEnabled;
{
    [mDefaults setBool: mouseEnabled forKey: MameMouseKey];
}

- (BOOL) isJoystickEnabled;
{
    return [mDefaults boolForKey: MameJoystickKey];
}

- (void) setJoystickEnabled: (BOOL) joystickEnabled;
{
    [mDefaults setBool: joystickEnabled forKey: MameJoystickKey];
}

- (BOOL) multiKeyboard;
{
    return [mDefaults boolForKey: MameMultiKeyboardKey];
}

- (void) setMultiKeyboard: (BOOL) multiKeyboard;
{
    [mDefaults setBool: multiKeyboard forKey: MameMultiKeyboardKey];
}

- (BOOL) multiMouse;
{
    return [mDefaults boolForKey: MameMultiMouseKey];
}

- (void) setMultiMouse: (BOOL) multiMouse;
{
    [mDefaults setBool: multiMouse forKey: MameMultiMouseKey];
}

- (float) joystickDeadzone;
{
    return [mDefaults floatForKey: MameJoystickDeadzoneKey];
}

- (void) setJoystickDeadzone: (float) joystickDeadzone;
{
    [mDefaults setFloat: joystickDeadzone forKey: MameJoystickDeadzoneKey];
}

- (float) joystickSaturation;
{
    return [mDefaults floatForKey: MameJoystickSaturationKey];
}

- (void) setJoystickSaturation: (float) joystickSaturation;
{
    [mDefaults setFloat: joystickSaturation forKey: MameJoystickSaturationKey];
}

#pragma mark -
#pragma mark Messages

- (BOOL) skipDisclaimer;
{
    return [mDefaults boolForKey: MameSkipDisclaimerKey];
}

- (BOOL) skipGameInfo;
{
    return [mDefaults boolForKey: MameSkipGameInfoKey];
}

- (BOOL) skipWarnings;
{
    return [mDefaults boolForKey: MameSkipWarningsKey];
}

#pragma mark -
#pragma mark Sound

- (int) sampleRate;
{
    return [mDefaults integerForKey: MameSampleRateKey];
}

- (BOOL) useSamples;
{
    return [mDefaults boolForKey: MameUseSamplesKey];
}

#pragma mark -
#pragma mark Graphics

- (BOOL) keepAspect;
{
    return [mDefaults boolForKey: MameKeepAspectKey];
}

- (void) setKeepAspect: (BOOL) keepAspect;
{
    [mDefaults setBool: keepAspect forKey: MameKeepAspectKey];
}

- (float) brightness;
{
    return [mDefaults floatForKey: MameBrightnessKey];
}

- (float) contrast;
{
    return [mDefaults floatForKey: MameContrastKey];
}

- (float) gamma;
{
    return [mDefaults floatForKey: MameGammaKey];
}

- (float) pauseBrightness;
{
    return [mDefaults floatForKey: MamePauseBrightnessKey];
}

#pragma mark -
#pragma mark Performance

//=========================================================== 
//  throttled 
//=========================================================== 
- (BOOL) throttled
{
    return [mDefaults boolForKey: MameThrottledKey];
}

- (void) setThrottled: (BOOL) flag
{
    [mDefaults setBool: flag forKey:MameThrottledKey];
}

- (BOOL) autoFrameSkip;
{
    return [mDefaults boolForKey: MameAutoFrameSkipKey];
}

- (void) setAutoFrameSkip: (BOOL) flag;
{
    [mDefaults setBool: flag forKey: MameAutoFrameSkipKey];
}

- (BOOL) refreshSpeed;
{
    return [mDefaults boolForKey: MameRefreshSpeedKey];
}

- (void) setRefreshSpeed: (BOOL) flag;
{
    [mDefaults setBool: flag forKey: MameRefreshSpeedKey];
}

#pragma mark -
#pragma mark Vector

- (float) beamWidth;
{
    return [mDefaults floatForKey: MameBeamWidthKey];
}

- (BOOL) antialiasBeam;
{
    return [mDefaults boolForKey: MameAntialiasBeamKey];
}

- (float) vectorFlicker;
{
    return [mDefaults floatForKey: MameVectorFlickerKey];
}

#pragma mark -

- (NSString *) saveGame;
{
    return [mDefaults stringForKey: MameSaveGameKey];
}

- (BOOL) autoSave;
{
    return [mDefaults boolForKey: MameAutosaveKey];
}

- (NSString *) bios;
{
    return [mDefaults stringForKey: MameBiosKey];
}

#pragma mark -
#pragma mark Integration with MAME options

- (void) copyToMameConfiguration: (MameConfiguration *) configuration;
{
    NSArray * romPaths = [NSArray arrayWithObjects:
        [self romPath], [self diskImagePath], nil];
    [configuration setRomPath: [romPaths componentsJoinedByString: @";"]];
    [configuration setSamplePath: [self samplePath]];
    [configuration setArtworkPath: [self artworkPath]];
    [configuration setDiffDirectory: [self diffDirectory]];
    [configuration setNvramDirectory: [self nvramDirectory]];
    [configuration setConfigDirectory: [self configDirectory]];
    [configuration setInputDirectory: [self inputDirectory]];
    [configuration setStateDirectory: [self stateDirectory]];
    [configuration setMemcardDirectory: [self memcardDirectory]];
    [configuration setSnapshotDirectory: [self snapshotDirectory]];
    [configuration setCtrlrPath: [self ctrlrPath]];
    [configuration setCommentDirectory: [self commentDirectory]];
    [configuration setFontPath: [self fontPath]];
    
#ifdef MAME_DEBUG
    [configuration setMameDebug: [self mameDebug]];
#endif
    [configuration setCheat: [self cheat]];
    
    [configuration setMouseEnabled: [self isMouseEnabled]];
    [configuration setJoystickEnabled: [self isJoystickEnabled]];
    [configuration setMultiKeyboard: [self multiKeyboard]];
    [configuration setMultiMouse: [self multiMouse]];
    [configuration setJoystickDeadzone: [self joystickDeadzone]];
    [configuration setJoystickSaturation: [self joystickSaturation]];
    
    [configuration setSkipDisclaimer: [self skipDisclaimer]];
    [configuration setSkipGameInfo: [self skipGameInfo]];
    [configuration setSkipWarnings: [self skipWarnings]];

    [configuration setSampleRate: [self sampleRate]];
    [configuration setUseSamples: [self useSamples]];
    
    [configuration setBrightness: [self brightness]];
    [configuration setContrast: [self contrast]];
    [configuration setGamma: [self gamma]];
    [configuration setPauseBrightness: [self pauseBrightness]];
    
    [configuration setBeam: [self beamWidth]];
    [configuration setAntialias: [self antialiasBeam]];
    [configuration setVectorFlicker: [self vectorFlicker]];
    
    [configuration setThrottle: [self throttled]];
    [configuration setAutoFrameSkip: [self autoFrameSkip]];
    [configuration setRefreshSpeed: [self refreshSpeed]];
    
    [configuration setSaveGame: [self saveGame]];
    [configuration setAutoSave: [self autoSave]];
    [configuration setBios: [self bios]];
}


#pragma mark -
#pragma mark UI

- (NSArray *) gamesSortDescriptors;
{
    NSArray * sortDescriptors = nil;
    NSData * data = [mDefaults dataForKey: MameGameSortDescriptorsKey];
    if (data != nil)
    {
        sortDescriptors = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    }
    
    if (sortDescriptors == nil)
    {
        NSSortDescriptor * descriptor =
            [[NSSortDescriptor alloc] initWithKey: @"longName"
                                        ascending: YES
                                         selector: @selector(caseInsensitiveCompare:)];
        
        sortDescriptors = [NSArray arrayWithObject: descriptor];
    }
    
    return sortDescriptors;
}

- (void) setGamesSortDescriptors: (NSArray *) gamesSortDescriptors;
{
    NSData * data = nil;
    if (gamesSortDescriptors != nil)
    {
        data = [NSKeyedArchiver archivedDataWithRootObject: gamesSortDescriptors];
    }
    [mDefaults setObject: data forKey: MameGameSortDescriptorsKey];
}

- (int) gameFilterIndex;
{
    return [mDefaults integerForKey: MameGameFilterIndexKey];
}

- (void) setGameFilterIndex: (int) gameFilterIndex;
{
    [mDefaults setInteger: gameFilterIndex forKey: MameGameFilterIndexKey];
}

- (BOOL) backgroundUpdateDebug;
{
    return [mDefaults boolForKey: MameBackgroundUpdateDebugKey];
}

#pragma mark -
#pragma mark Debugging

- (BOOL) forceUpdateGameList;
{
    return [mDefaults boolForKey: MameForceUpdateGameListKey];
}

- (BOOL) deleteOldGames;
{
    return [mDefaults boolForKey: MameDeleteOldGamesKey];
}

- (BOOL) logAllToConsole;
{
    return [mDefaults boolForKey: MameLogAllToConsoleKey];
}

@end

@implementation MamePreferences (Private)

static int availableCpus()
{
	host_basic_info_data_t hostInfo;
	mach_msg_type_number_t infoCount;
	
	infoCount = HOST_BASIC_INFO_COUNT;
	host_info(mach_host_self(), HOST_BASIC_INFO, 
			  (host_info_t)&hostInfo, &infoCount);
    return hostInfo.avail_cpus;
}

- (BOOL) hasMultipleCPUs;
{
    if (availableCpus() > 1)
        return YES;
    else
        return NO;
}

- (void) initializeDefaultPaths: (NSMutableDictionary *) defaultValues;
{
    const struct
    {
        NSString * preference;
        NSString * path;
    }
    defaultPaths[] = {
    { MameRomPath,          @"ROMs" },
    { MameDiskImagePath,    @"Hard Disk Images" },
    { MameSamplePath,       @"Sound Samples" },
    { MameConfigPath,       @"Config" },
    { MameCtrlrPath,        @"Control Panels" },
    { MameNvramPath,        @"NVRAM" },
    { MameMemcardPath,      @"Memcard" },
    { MameInputPath,        @"Input" },
    { MameStatePath,        @"States" },
    { MameArtworkPath,      @"Cabinet Art" },
    { MameSnapshotPath,     @"Screenshots" },
    { MameDiffPath,         @"Diffs" },
    { MameFontPath,         @"Fonts" },
    { MameEffectPath,       @"Effects" },
    { 0, nil }
    };

    NSFileManager * fileManager = [NSFileManager defaultManager];

    NSString * baseDirectory = MameApplicationSupportDirectory();

    int i;
    for (i = 0; defaultPaths[i].path != nil; i++)
    {
        NSString * path = [baseDirectory stringByAppendingPathComponent: defaultPaths[i].path];
        if (![fileManager fileExistsAtPath: path])
            [fileManager createDirectoryAtPath: path attributes: nil];
        [defaultValues setObject: path forKey: defaultPaths[i].preference];
    }
}

@end

NSString * MameApplicationSupportDirectory(void)
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSCAssert([paths count] > 0, @"Could not locate NSApplicationSupportDirectory in user domain");
    
    NSString * directory = [paths objectAtIndex: 0];
    if (![fileManager fileExistsAtPath: directory])
        [fileManager createDirectoryAtPath: directory attributes: nil];
    directory = [directory stringByAppendingPathComponent: @"MAME OS X"];
    if (![fileManager fileExistsAtPath: directory])
        [fileManager createDirectoryAtPath: directory attributes: nil];
    return directory;
}

