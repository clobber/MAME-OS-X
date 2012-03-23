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

@class MameController;
@class GameMO;
@class BackgroundUpdaterContext;

@interface BackgroundUpdater : NSObject
{
    BackgroundUpdaterContext * mFsm;

    // Resources that get released after background completion
    BOOL mRunning;
    BOOL mSavedRunning;
    BOOL mWorkDone;
    unsigned mCurrentGameIndex;
    unsigned mUpdateGameListIteration;
    NSArray * mShortNames;
    GameMO * mCurrentGame;
    NSEnumerator * mGameEnumerator;
    NSTimeInterval mLastSave;
    NSTimeInterval mLastStatus;
    BOOL mIdle;
    BOOL mAuditing;
    
    // Weak references
    MameController * mController;
}

- (id) initWithMameController: (MameController *) controller;

- (void) start;
- (void) pause;
- (void) resume;

- (BOOL) isRunning;

- (void) auditGames: (NSArray *) games;
- (void) auditAllGames;
- (void) auditUnauditedGames;
- (void) abortAudit;

- (BOOL) isIdle;
- (void) setIdle: (BOOL) idle;

- (BOOL) auditing;
- (void) setAuditing: (BOOL) auditing;

#pragma mark -
#pragma mark State Machine Actions

- (void) saveState;
- (void) restoreState;

- (void) prepareToUpdateGameList;
- (void) updateGameList;
- (void) prepareToAuditAllGames;
- (void) prepareToAuditGames: (NSArray *) games;
- (void) auditGames;
- (void) cleanUp;
- (void) defaultWork;

@end
