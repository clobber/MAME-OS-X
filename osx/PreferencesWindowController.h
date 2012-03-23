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
#import "DBPrefsWindowController.h"

@class MameController;

@interface PreferencesWindowController : DBPrefsWindowController
{
    IBOutlet NSView * mGeneralPreferenceView;
    IBOutlet NSView * mInputsPreferenceView;
    IBOutlet NSView * mMessagesPreferenceView;
    IBOutlet NSView * mVideoPreferencesView;
    IBOutlet NSView * mVectorPreferencesView;
    
    IBOutlet NSObjectController * mControllerAlias;
    IBOutlet NSPopUpButton * mRomDirectory;
    IBOutlet NSPopUpButton * mDiskImageDirectory;
    IBOutlet NSPopUpButton * mSamplesDirectory;
    IBOutlet NSPopUpButton * mArtworkDirectory;
    
    NSArray * mWindowedZoomLevels;
    NSArray * mFrameRenderingValues;
    NSArray * mRenderingThreadValues;
    NSArray * mFullScreenZoomValues;
    NSDictionary * mButtonsByKey;
    MameController * mMameController;
}

- (id) initWithMameController: (MameController *) mameController;

- (IBAction) chooseRomDirectory: (id) sender;
- (IBAction) chooseDiskImageDirectory: (id) sender;
- (IBAction) chooseSamplesDirectory: (id) sender;
- (IBAction) chooseArtworkDirectory: (id) sender;

- (IBAction) resetToDefaultsGeneral: (id) sender;
- (IBAction) resetToDefaultsInputs: (id) sender;
- (IBAction) resetToDefaultsMessages: (id) sender;
- (IBAction) resetToDefaultsVideo: (id) sender;
- (IBAction) resetToDefaultsVector: (id) sender;

- (int) logLevelIndex;
- (void) setLogLevelIndex: (int) logLevelIndex;

- (unsigned) windowedZoomLevelIndex;
- (void) setWindowedZoomLevelIndex: (unsigned) windowedZoomLevelIndex;

- (unsigned) fullScreenZoomLevelIndex;
- (void) setFullScreenZoomLevelIndex: (unsigned) fullScreenZoomLevelIndex;

- (unsigned) frameRenderingIndex;
- (void) setFrameRenderingIndex: (unsigned) frameRenderingIndex;

- (unsigned) renderingThreadIndex;
- (void) setRenderingThreadIndex: (unsigned) renderingThreadIndex;

- (MameController *) mameController;

@end
