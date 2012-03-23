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

#import "PreferencesWindowController.h"
#import "MamePreferences.h"
#import "JRLog.h"

enum
{
    LogErrorIndex = 0,
    LogWarnIndex = 1,
    LogInfoIndex = 2,
    LogDebugIndex = 3
};

@interface PreferencesWindowController (Private)

- (void) updatePopUpButtons;

- (void) setPopUpMenu: (NSPopUpButton *) popupButton withPath: (NSString *) path;

- (void) chooseDirectoryForKey: (NSString *) userDataKey
                     withTitle: (NSString *) title;

- (void) chooseDirectoryDidEnd: (NSOpenPanel *) panel
                    returnCode: (int) returnCode
                   contextInfo: (void *) contextInfo;

- (void) resetDefaultsWithKeys: (NSArray *) keys;

@end

@implementation PreferencesWindowController

- (id) initWithMameController: (MameController *) mameController;
{
    self = [super initWithWindowNibName: @"Preferences"];
    if (self == nil)
        return nil;
    
        // Don't retain to avoid a circular reference count
    mMameController = mameController;

    mWindowedZoomLevels = [[NSArray alloc] initWithObjects:
        MameZoomLevelActual,
        MameZoomLevelDouble,
        MameZoomLevelMaximumIntegral,
        MameZoomLevelMaximum,
        nil];
   
    mFrameRenderingValues = [[NSArray alloc] initWithObjects:
        MameFrameRenderingDefaultValue,
        MameRenderFrameInOpenGLValue,
        MameRenderFrameInCoreImageValue,
        nil];

    mRenderingThreadValues = [[NSArray alloc] initWithObjects:
        MameRenderingThreadDefaultValue,
        MameRenderInCoreVideoThreadValue,
        MameRenderInMameThreadValue,
        nil];
    
    mFullScreenZoomValues = [[NSArray alloc] initWithObjects:
        MameFullScreenMaximumValue,
        MameFullScreenIntegralValue,
        MameFullScreenIndependentIntegralValue,
        MameFullScreenStretchValue,
        nil];
    
	[self setCrossFade: NO];
	[self setShiftSlowsAnimation: NO];
    [self setResizeToMaxWidth: YES];
    [self setUseUnifiedStyle: YES];
    
    return self;
}

- (void) awakeFromNib
{
    [mControllerAlias setContent: self];

    mButtonsByKey = [[NSDictionary alloc] initWithObjectsAndKeys:
        mRomDirectory, MameRomPath,
        mDiskImageDirectory, MameDiskImagePath,
        mSamplesDirectory, MameSamplePath,
        mArtworkDirectory, MameArtworkPath,
        nil];

    [self updatePopUpButtons];
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mWindowedZoomLevels release];
    [mFrameRenderingValues release];
    [mRenderingThreadValues release];
    [mFullScreenZoomValues release];
    [mButtonsByKey release];
    
    mWindowedZoomLevels = nil;
    mFrameRenderingValues = nil;
    mRenderingThreadValues = nil;
    mFullScreenZoomValues = nil;
    mButtonsByKey = nil;
    [super dealloc];
}

- (void) setupToolbar
{
	[self addView: mGeneralPreferenceView label: @"General"];
    [self addView: mInputsPreferenceView label: @"Inputs"];
    [self addView: mMessagesPreferenceView label: @"Messages"];
    [self addView: mVideoPreferencesView label: @"Video"];
    [self addView: mVectorPreferencesView label: @"Vector"];
}

- (NSDictionary *) name: (NSString *) name stringValue: (NSString *) value
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name", value, @"value", nil];
}

- (int) logLevelIndex;
{
    JRLogLevel logLevel = [[self class] defaultJRLogLevel];
    switch (logLevel)
    {
        case JRLogLevel_Error:
            return LogErrorIndex;
            
        case JRLogLevel_Warn:
            return LogWarnIndex;
            
        case JRLogLevel_Info:
            return LogInfoIndex;
                
        case JRLogLevel_Debug:
            return LogDebugIndex;
            
        default:
            JRLogError(@"Unknown log level: %d", logLevel);
            return -1;
    }
}

- (void) setLogLevelIndex: (int) logLevelIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];

    switch (logLevelIndex)
    {
        case LogErrorIndex:
            [preferences setJrLogLevel: @"ERROR"];
            [[self class] setDefaultJRLogLevel: JRLogLevel_Error];
            break;
            
        case LogWarnIndex:
            [preferences setJrLogLevel: @"WARN"];
            [[self class] setDefaultJRLogLevel: JRLogLevel_Warn];
            break;
            
        case LogInfoIndex:
            [preferences setJrLogLevel: @"INFO"];
            [[self class] setDefaultJRLogLevel: JRLogLevel_Info];
            break;
            
        case LogDebugIndex:
            [preferences setJrLogLevel: @"DEBUG"];
            [[self class] setDefaultJRLogLevel: JRLogLevel_Debug];
            break;
            
        default:
            JRLogError(@"Unknown log level index: %d", logLevelIndex);
            break;
    }
}

- (unsigned) windowedZoomLevelIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    return [mWindowedZoomLevels indexOfObject: [preferences windowedZoomLevel]];
}

- (void) setWindowedZoomLevelIndex: (unsigned) windowedZoomLevelIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    [preferences setWindowedZoomLevel:
        [mWindowedZoomLevels objectAtIndex: windowedZoomLevelIndex]];
}

- (unsigned) fullScreenZoomLevelIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    NSString * zoomLevel = [preferences fullScreenZoomLevel];
    return [mFullScreenZoomValues indexOfObject: zoomLevel];
}

- (void) setFullScreenZoomLevelIndex: (unsigned) fullScreenZoomLevelIndex;
{
    NSString * zoomLevel =
        [mFullScreenZoomValues objectAtIndex: fullScreenZoomLevelIndex];
    MamePreferences * preferences = [MamePreferences standardPreferences];
    [preferences setFullScreenZoomLevel: zoomLevel];
}

- (unsigned) frameRenderingIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    return [mFrameRenderingValues indexOfObject: [preferences frameRendering]];
}

- (void) setFrameRenderingIndex: (unsigned) frameRenderingIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    [preferences setFrameRendering:
        [mFrameRenderingValues objectAtIndex: frameRenderingIndex]];
}

- (unsigned) renderingThreadIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    return [mRenderingThreadValues indexOfObject:
        [preferences renderingThread]];
}

- (void) setRenderingThreadIndex: (unsigned) renderingThreadIndex;
{
    MamePreferences * preferences = [MamePreferences standardPreferences];
    [preferences setRenderingThread:
        [mRenderingThreadValues objectAtIndex: renderingThreadIndex]];
}

- (IBAction) chooseRomDirectory: (id) sender;
{
    [self chooseDirectoryForKey: MameRomPath
                      withTitle: @"Choose ROM Directory"];
}

- (IBAction) chooseDiskImageDirectory: (id) sender;
{
    [self chooseDirectoryForKey: MameDiskImagePath
                      withTitle: @"Choose Disk Image Directory"];
}

- (IBAction) chooseSamplesDirectory: (id) sender;
{
    [self chooseDirectoryForKey: MameSamplePath
                      withTitle: @"Choose Sound Samples Directory"];
}

- (IBAction) chooseArtworkDirectory: (id) sender;
{
    [self chooseDirectoryForKey: MameArtworkPath
                      withTitle: @"Choose Artwork Directory"];
}

- (IBAction) resetToDefaultsGeneral: (id) sender;
{
    NSArray * keys = [NSArray arrayWithObjects:
        MameRomPath, MameDiskImagePath, MameSamplePath, MameArtworkPath,
        MameCheckUpdatesAtStartupKey,
        MameSmoothFontKey,
        nil];
    [self resetDefaultsWithKeys: keys];
    [self updatePopUpButtons];
}

- (IBAction) resetToDefaultsInputs: (id) sender;
{
    NSArray * keys = [NSArray arrayWithObjects:
        MameMouseKey,
        MameJoystickKey,
        MameMultiKeyboardKey,
        MameMultiMouseKey,
        MameJoystickDeadzoneKey,
        MameJoystickSaturationKey,
        nil];
    [self resetDefaultsWithKeys: keys];
}

- (IBAction) resetToDefaultsMessages: (id) sender;
{
    NSArray * keys = [NSArray arrayWithObjects:
        MameSkipDisclaimerKey, MameSkipGameInfoKey, MameSkipWarningsKey,
        nil];
    [self resetDefaultsWithKeys: keys];
    [self setLogLevelIndex: LogWarnIndex];
}

- (IBAction) resetToDefaultsVideo: (id) sender;
{
    NSArray * keys = [NSArray arrayWithObjects:
        MameSyncToRefreshKey,
        MameThrottledKey,
        MameLinearFilterKey,
        MameKeepAspectKey,
        MameFullScreenKey,
        MameSwitchResolutionsKey,
        MameFullScreenZoomLevelKey,
        MameWindowedZoomLevelKey,
        MameFrameRenderingKey,
        MameRenderingThreadKey,
        nil];

    [self willChangeValueForKey: @"windowedZoomLevelIndex"];
    [self willChangeValueForKey: @"frameRenderingIndex"];
    [self willChangeValueForKey: @"renderingThreadIndex"];
    [self willChangeValueForKey: @"fullScreenZoomLevelIndex"];

    [self resetDefaultsWithKeys: keys];
    
    [self didChangeValueForKey: @"windowedZoomLevelIndex"];
    [self didChangeValueForKey: @"frameRenderingIndex"];
    [self didChangeValueForKey: @"renderingThreadIndex"];
    [self didChangeValueForKey: @"fullScreenZoomLevelIndex"];
}

- (IBAction) resetToDefaultsVector: (id) sender;
{
    NSArray * keys = [NSArray arrayWithObjects:
        MameBeamWidthKey,
        MameAntialiasBeamKey,
        MameVectorFlickerKey,
        nil];
    [self resetDefaultsWithKeys: keys];
}

//=========================================================== 
// - mameController
//=========================================================== 
- (MameController *) mameController
{
    return mMameController; 
}

@end

@implementation PreferencesWindowController (Private)

- (void) updatePopUpButtons;
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * romPath = [defaults stringForKey: MameRomPath];
    NSString * diskImagePath = [defaults stringForKey: MameDiskImagePath];
    NSString * samplePath = [defaults stringForKey: MameSamplePath];
    NSString * artworkPath = [defaults stringForKey: MameArtworkPath];
    
    [self setPopUpMenu: mRomDirectory withPath: romPath];
    [self setPopUpMenu: mDiskImageDirectory withPath: diskImagePath];
    [self setPopUpMenu: mSamplesDirectory withPath: samplePath];
    [self setPopUpMenu: mArtworkDirectory withPath: artworkPath];
}

// Given a full path to a file, display the leaf name and the finder icon associated
// with that folder in the first item of the download folder popup.
//
- (void) setPopUpMenu: (NSPopUpButton *) popupButton withPath: (NSString *) path;
{
    NSMenuItem* placeholder = [popupButton itemAtIndex: 0];
    if (!placeholder)
        return;
    
    // get the finder icon and scale it down to 16x16
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile: path];
    [icon setScalesWhenResized: YES];
    [icon setSize: NSMakeSize(16.0, 16.0)];
    
    // set the title to the leaf name and the icon to what we gathered above
    [placeholder setTitle: [path lastPathComponent]];
    [placeholder setImage: icon];
    
    // ensure first item is selected
    [popupButton selectItemAtIndex: 0];
}

- (void) chooseDirectoryForKey: (NSString *) userDataKey
                     withTitle: (NSString *) title;
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    int result;
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    
    [panel setTitle: title];
    [panel setPrompt: @"Choose"];
    [panel setAllowsMultipleSelection: NO];
    [panel setCanChooseFiles: NO];
    [panel setCanChooseDirectories: YES];
    [panel setCanCreateDirectories: YES];
    [panel beginSheetForDirectory: [defaults stringForKey: userDataKey]
                             file: nil
                   modalForWindow: [self window]
                    modalDelegate: self
                   didEndSelector: @selector(chooseDirectoryDidEnd:returnCode:contextInfo:)
                      contextInfo: userDataKey];
}

- (void) chooseDirectoryDidEnd: (NSOpenPanel *) panel
                    returnCode: (int) returnCode
                   contextInfo: (void *) contextInfo;
{
    NSString * key = (NSString *) contextInfo;
    NSPopUpButton * button = [mButtonsByKey objectForKey: key];
    
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    if (returnCode == NSOKButton)
    {
        NSString * newPath = [panel filename];
        [defaults setValue: newPath forKey: key];
        // Update menu
        [self setPopUpMenu: button withPath: newPath];
    }
    else
    {
        [button selectItemAtIndex: 0];
    }
}

- (void) resetDefaultsWithKeys: (NSArray *) keys;
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSEnumerator * e = [keys objectEnumerator];
    NSString * key;
    while (key = [e nextObject])
    {
        [defaults setValue: nil forKey: key];
    }
}

@end
