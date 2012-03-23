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


@interface RomAuditWindowController : NSWindowController
{
    IBOutlet NSProgressIndicator * mProgress;
    IBOutlet NSTableView * mResultsTable;
    IBOutlet NSTextView * mNotesView;
    IBOutlet NSObjectController * mControllerAlias;
    IBOutlet NSArrayController * mResultsController;
    IBOutlet NSPanel * mProgressPanel;
    IBOutlet NSTextField * mAuditStatusField;

    NSString * mStatus;
    NSString * mSearchString;
    NSMutableArray * mResults;
    BOOL mRunning;
    BOOL mShowGood;
    NSCalendarDate *mAuditDateTime;
    unsigned int mTotalDriverCount;
    
    // only set during audit
    unsigned int mCurrentAuditIndex;
    NSTimer *mUpdateTimer;
    NSMutableArray *mResultsAccumulator;
}

- (IBAction) startAudit: (id) sender;
- (IBAction) cancel: (id) sender;

- (NSString *) status;

- (NSString *) searchString;
- (void) setSearchString: (NSString *) searchString;

- (BOOL) showGood;
- (void) setShowGood: (BOOL) showGood;

- (NSMutableArray *) results;
-  (void) setResults: (NSMutableArray *) results;

- (NSString *) auditStatusSummaryText;
@end
