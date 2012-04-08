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
#import <Quartz/Quartz.h>
#import "JRLog.h"

#if defined(__cplusplus)
extern "C++" {
#endif
    
#include "osdepend.h"
#include "render.h"

#if defined(__cplusplus)
}
#endif

@class PreferencesWindowController;
@class MameView;
@class MameConfiguration;
@class VersionChecker;
@class AudioEffectWindowController;
@class BackgroundUpdater;
@class RBSplitSubview;
@class GroupMO;

@interface MameController : NSObject <JRLogLogger>
{
    IBOutlet MameView * mMameView;
    IBOutlet NSDrawer * mDrawer;
    IBOutlet NSWindow * mOpenPanel;
    IBOutlet VersionChecker *mVersionChecker;
    IBOutlet NSMenu * mEffectsMenu;
    IBOutlet NSMenu * mGameFilterMenu;
    IBOutlet NSToolbar * mToolbar;
    IBOutlet QCView * mScreenshotView;
    IBOutlet NSProgressIndicator * mProgressIndicator;

    IBOutlet NSImageView * mDragView;
    IBOutlet RBSplitSubview * mGameSplit;
    IBOutlet RBSplitSubview * mScreenshotSplit;
    
    IBOutlet NSPanel * mMameLogPanel;
    IBOutlet NSTextView * mMameLogView;
    
    IBOutlet NSArrayController * mAllGamesController;
    IBOutlet NSTableView * mGamesTable;
    IBOutlet NSTableColumn * mFavoriteColumn;
    IBOutlet NSView * mAuditTableSubstitutionView;
    
    IBOutlet NSPanel * mInfoPanel;
    IBOutlet NSTextView * mInfoAuditNotes;
    
    // Size of other elements around the view
    NSSize mExtraWindowSize;
    NSRect mOriginalOpenFrame;
    
    PreferencesWindowController * mPreferencesController;
    AudioEffectWindowController * mAudioEffectsController;

    MameConfiguration * mConfiguration;

    BOOL mMameIsRunning;
    
    NSMutableArray * mEffectNames;
    NSMutableDictionary * mEffectPathsByName;
    BOOL mVisualEffectEnabled;
    int mCurrentEffectIndex;

    NSString * mGameName;
    NSString * mLoadingMessage;
    NSMutableArray * mPreviousGames;
    BOOL mGameLoading;
    BOOL mGameRunning;
    BOOL mTerminateOnGameExit;
    BOOL mTerminateReplyOnGameExit;
    
    NSDictionary * mLogAttributes;
    NSDictionary * mLogErrorAttributes;
    NSDictionary * mLogWarningAttributes;
    NSDictionary * mLogInfoAttributes;
    NSDictionary * mLogDebugAttributes;
    id<JRLogLogger> mOriginalLogger;
    
    NSPersistentStoreCoordinator * persistentStoreCoordinator;
    NSManagedObjectModel * managedObjectModel;
    NSManagedObjectContext * managedObjectContext;
    BOOL mFreshPersistentStore;
    
    NSArray * mGameSortDescriptors;
    NSString * mFilterString;
    int mGameFilterIndex;
    BackgroundUpdater * mUpdater;
    BOOL mShowClones;
    NSString * mStatusText;
}

#pragma mark -
#pragma mark Core Data

- (void) handleCoreDataError: (NSError *) error;
- (NSManagedObjectModel *) managedObjectModel;
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
- (NSManagedObjectContext *) managedObjectContext;
- (IBAction) saveAction: (id) sender;

#pragma mark -

- (NSArray *) gameSortDescriptors;
- (void) setGameSortDescriptors: (NSArray *) theGameSortDescriptors;

- (void) setFilterString: (NSString *) filterString;
- (NSString *) filterString;

- (IBAction) gameFilterAction: (id) sender;

- (void) setGameFilterIndex: (int) gameFilterIndex;
- (int) gameFilterIndex;

- (BOOL) showClones;
- (void) setShowClones: (BOOL) flag;

- (IBAction) toggleFavorite: (id) sender;

- (IBAction) exportFavorites: (id) sender;
- (IBAction) importFavorites: (id) sender;
- (void) restoreFavorites;

- (NSArray *) selectedGames;

- (IBAction) refreshGames: (id) sender;

- (void) rearrangeGames;

- (NSString *) statusText;
- (void) setStatusText: (NSString *) theStatusText;

#pragma mark -
#pragma mark State

- (BOOL) canAuditGames;
- (BOOL) canAbortAudit;

- (unsigned) selectionCount;
- (BOOL) hasSelection;
- (BOOL) hasNoSelection;
- (BOOL) hasOneSelection;
- (BOOL) hasMultipleSelection;

#pragma mark -
#pragma mark Background Callbacks

- (void) backgroundUpdateWillStart;

- (void) backgroundUpdateWillBeginAudits: (unsigned) totalAudits;

- (void) backgroundUpdateAuditStatus: (unsigned) numberCompleted;

- (void) backgroundUpdateWillFinish;

- (IBAction) toggleScreenshot: (id) sender;

- (IBAction) restoreOpenFrame: (id) sender;

#pragma mark -

- (MameView *) mameView;

- (BOOL) visualEffectEnabled;
- (void) setVisualEffectEnabled: (BOOL) flag;

- (int) currentEffectIndex;
- (void) setCurrentEffectIndex: (int) currentEffectIndex;

- (void) setCurrentVisualEffectName: (NSString *) effectName;

- (NSArray *) visualEffectNames;

- (IBAction) nextVisualEffect: (id) sender;
- (IBAction) previousVisualEffects: (id) sender;
- (IBAction) visualEffectsMenuChanged: (id) sender;
- (IBAction) toggleThrottled: (id) sender;
- (IBAction) toggleSubstitution: (id) sender;
- (BOOL) isTableSubstitutionHidden;
- (void) setTableSubstitionHidden: (BOOL) hidden;

- (BOOL) syncToRefresh;
- (void) setSyncToRefresh: (BOOL) flag;

- (BOOL) fullScreen;
- (void) setFullScreen: (BOOL) fullScreen;

- (BOOL) linearFilter;
- (void) setLinearFilter: (BOOL) linearFilter;

- (BOOL) audioEffectEnabled;
- (void) setAudioEffectEnabled: (BOOL) flag;

- (IBAction) showAudioEffectsPanel: (id) sender;

- (BOOL) isGameLoading;
- (BOOL) isGameRunning;

- (NSString *) loadingMessage;

- (NSArray *) previousGames;

- (IBAction) showPreferencesPanel: (id) sender;

- (IBAction) togglePause: (id) sender;
- (IBAction) nullAction: (id) sender;

- (IBAction) raiseOpenPanel: (id) sender;
- (IBAction) endOpenPanel: (id) sender;
- (IBAction) cancelOpenPanel: (id) sender;
- (IBAction) hideOpenPanel: (id) sender;

- (IBAction) resizeToActualSize: (id) sender;
- (IBAction) resizeToDoubleSize: (id) sender;
- (IBAction) resizeToOptimalSize: (id) sender;
- (IBAction) resizeToMaximumIntegralSize: (id) sender;
- (IBAction) resizeToMaximumSize: (id) sender;

- (IBAction) auditRoms: (id) sender;

- (IBAction) auditSelectedGames: (id) sender;
- (IBAction) auditAllGames: (id) sender;
- (IBAction) auditUnauditedGames: (id) sender;
- (IBAction) abortAudit: (id) sender;
- (IBAction) resetAuditStatus: (id) sender;

- (IBAction) showLogWindow: (id) sender;

- (IBAction) clearLogWindow: (id) sender;

- (IBAction) showReleaseNotes: (id) sender;

- (IBAction) showWhatsNew: (id) sender;

- (void) logWithLevel: (JRLogLevel) callerLevel
             instance: (NSString*) instance
                 file: (const char*) file
                 line: (unsigned) line
             function: (const char*) function
              message: (NSString*) message;

#pragma mark -
#pragma mark MameView delegates

- (void) mameWillStartGame: (NSNotification *) notification;

- (void) mameDidFinishGame: (NSNotification *) notification;

- (void) mameErrorMessage: (NSString *) message;

- (void) mameWarningMessage: (NSString *) message;

- (void) mameInfoMessage: (NSString *) message;

- (void) mameDebugMessage: (NSString *) message;

- (void) mameLogMessage: (NSString *) message;

@end
