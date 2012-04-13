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

#import "RomAuditWindowController.h"
#import "RomAuditSummary.h"
#import "MameConfiguration.h"
//#include "driver.h"
#include "emu.h"
#include "audit.h"

@interface RomAuditWindowController (Private)

- (void) setStatus: (NSString *) status;
- (void) updatePredicate;

- (void) saveResults;
- (void) loadResults;

@end

@implementation RomAuditWindowController
+ (void) initialize
{
    [self setKeys:[NSArray arrayWithObjects: @"results", @"mAuditDate", @"mTotalDriverCount", nil]
             triggerChangeNotificationsForDependentKey: @"auditStatusSummaryText"];
}

- (id) init
{
    self = [super initWithWindowNibName: @"RomAudit"];
    if (self == nil)
        return nil;
    
    mStatus = @"";
    mShowGood = NO;
    mResults = [[NSMutableArray alloc] init];
    mTotalDriverCount = 0;
    mAuditDateTime = nil;
    
    return self;
}

- (void) awakeFromNib
{
    // Avoid a memory leak.  See steps here, plus "Step 4":
    // http://theobroma.treehouseideas.com/document.page/18
    // Or:
    // http://www.cocoabuilder.com/archive/message/cocoa/2006/10/24/173255
    [mControllerAlias setContent: self];

    [self loadResults];
    
    [self setStatus: @""];
    [self updatePredicate];
}

- (void) dealloc
{
    [mStatus release];
    [mSearchString release];
    [mResults release];
    [mAuditDateTime release];
    [mUpdateTimer release];
    [mResultsAccumulator release];
    
    [super dealloc];
}

- (void) windowWillClose: (NSNotification *) notification
{
    [mControllerAlias setContent: nil];
}

- (NSString *) status;
{
    return mStatus;
}

- (NSString *) searchString;
{
    return mSearchString;
}

- (void) setSearchString: (NSString *) searchString;
{
    [searchString retain];
    [mSearchString release];
    mSearchString = searchString;
    [self updatePredicate];
}

- (BOOL) showGood;
{
    return mShowGood;
}

- (void) setShowGood: (BOOL) showGood;
{
    mShowGood = showGood;
    [self updatePredicate];
}

- (void) auditDone: sender
{
    [mUpdateTimer invalidate];
    [mUpdateTimer release];
    mUpdateTimer = nil;

    [self willChangeValueForKey: @"auditStatusSummaryText"];
    [self setStatus: @""];
    [self setResults: mResultsAccumulator];
    
    [mResultsAccumulator release];
    mResultsAccumulator = nil;

    [mAuditDateTime release];
    mAuditDateTime = [[NSCalendarDate calendarDate] retain];
    
    [self saveResults];
    [self didChangeValueForKey: @"auditStatusSummaryText"];    

    [NSApp abortModal];
}

- (void) updateAuditStatusAndProgress: sender
{
    NSString *statusString;
    @synchronized(mResultsAccumulator) {
        statusString = [NSString stringWithFormat: @"%d of %d audited (%@ last audited).", mCurrentAuditIndex, mTotalDriverCount, [mResultsAccumulator lastObject]];
    }
    [self setStatus: statusString];
    [mProgress setDoubleValue: ((double)mCurrentAuditIndex) / ((double) mTotalDriverCount)];
}

- (void) auditThread: sender; // designed to run on a thread
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    FILE * output = stdout;
	int correct = 0;
	int incorrect = 0;
	int notfound = 0;
	int total;
    
	mTotalDriverCount = 0; // count drivers
	for (mCurrentAuditIndex = 0; drivers[mCurrentAuditIndex]; mCurrentAuditIndex++)
        mTotalDriverCount++;
    
    [self performSelectorOnMainThread: @selector(setStatus:)
                           withObject: [NSString stringWithFormat: @"Auditing %d drivers..", mTotalDriverCount]
                        waitUntilDone: NO];    
    
    double totalf = mTotalDriverCount; 
	/* now iterate over drivers */
	for (mCurrentAuditIndex = 0; drivers[mCurrentAuditIndex]; mCurrentAuditIndex++)
	{
		audit_record * auditRecords;
		int recordCount;
		int res;
        
        if (!mRunning) {
            break;
        }
                
        NSAutoreleasePool * loopPool = [[NSAutoreleasePool alloc] init];
        running_machine * machine;
		/* audit the ROMs in this set */
        recordCount = audit_images(machine->options(), drivers[mCurrentAuditIndex], AUDIT_VALIDATE_FAST, &auditRecords);
		//recordCount = audit_images([[MameConfiguration defaultConfiguration] coreOptions],
        //                           drivers[mCurrentAuditIndex], AUDIT_VALIDATE_FAST, &auditRecords);
        RomAuditSummary * summary =
            [[RomAuditSummary alloc] initWithGameIndex: mCurrentAuditIndex
                                           recordCount: recordCount
                                               records: auditRecords];
        free(auditRecords);

        @synchronized(mResultsAccumulator) {
            [mResultsAccumulator addObject: summary];
        }
        [summary release];

        [loopPool release];
	}
    [self performSelectorOnMainThread: @selector(auditDone:)
                           withObject: nil
                        waitUntilDone: NO];

    [pool release];
}

- (IBAction) startAudit: (id) sender;
{
    [mProgress setDoubleValue: 0.0];
    [NSApp beginSheet: mProgressPanel
       modalForWindow: [self window]
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];

    mRunning = YES;
    
    mResultsAccumulator = [[NSMutableArray alloc] init];

    [NSThread detachNewThreadSelector: @selector(auditThread:)
                             toTarget: self
                           withObject: nil];
    
    mUpdateTimer = [[NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateAuditStatusAndProgress:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:mUpdateTimer forMode:NSModalPanelRunLoopMode];
   
    [NSApp runModalForWindow: mProgressPanel];
    [NSApp endSheet: mProgressPanel];
    [mProgressPanel orderOut: self];
    
}

- (IBAction) cancel: (id) sender;
{
    mRunning = NO;
}

- (NSMutableArray *) results;
{
    return mResults;
}

-  (void) setResults: (NSMutableArray *) results;
{
    if (mResults != results)
	{
        [mResults autorelease];
        mResults = [results mutableCopy];
    }
}

- (NSString *) auditStatusSummaryText;
{
    if (!mAuditDateTime)
        return @"Audit data needs updating.";
    
    BOOL complete = (mTotalDriverCount == [[self results] count]);
    
    if (complete)
        return [NSString stringWithFormat: @"Complete audit (%d drivers) as of %@.", mTotalDriverCount, mAuditDateTime];
    else
        return [NSString stringWithFormat: @"Incomplete audit (%d/%d drivers) as of %@", [[self results] count], mTotalDriverCount, mAuditDateTime];
}
@end

@implementation RomAuditWindowController (Private)


- (void) setStatus: (NSString *) status;
{
    [status retain];
    [mStatus release];
    mStatus = status;
}

- (void) updatePredicate;
{
    NSPredicate * predicate;
    if (mSearchString != nil)
    {
        if (mShowGood) {
        predicate = [NSPredicate predicateWithFormat:
            @"gameName contains[c] %@ OR description contains[c] %@",
            mSearchString, mSearchString];
        }
        else
        {
            predicate = [NSPredicate predicateWithFormat:
                @"(gameName contains[c] %@ OR description contains[c] %@) and status != 0",
                mSearchString, mSearchString];
        }
    }
    else
    {
        if (mShowGood)
            predicate = nil;
        else
        {
            predicate = [NSPredicate predicateWithFormat: @"status != 0"];
        }
    }
    [mResultsController setFilterPredicate: predicate];
}


- (NSString *) auditFilePath
{
    static NSString *auditFilePath = nil;
    if (!auditFilePath) {
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSAssert([paths count] > 0, @"Could not locate NSLibraryDirectory in user domain");
        
        NSString * baseDirectory = [paths objectAtIndex: 0];
        baseDirectory = [baseDirectory stringByAppendingPathComponent: @"MAME OS X"];
        
        NSAssert([[NSFileManager defaultManager] fileExistsAtPath: baseDirectory], @"Application Support directory should have already been created.");
        
        auditFilePath = [[baseDirectory stringByAppendingPathComponent: @"Last ROM Audit.nscoderspew"] retain];
    }
    
    return auditFilePath;
}

- (void) saveResults;
{
    NSString *auditFilePath = [self auditFilePath];
    NSMutableDictionary *savedState = [NSMutableDictionary dictionary];
    [savedState setObject: [self valueForKey: @"results"] forKey: @"audit list"];
    [savedState setObject: [self valueForKey: @"mAuditDateTime"] forKey: @"audit date"];
    [savedState setObject: [self valueForKey: @"mTotalDriverCount"] forKey: @"total driver count"];    
    
    [NSKeyedArchiver archiveRootObject: savedState toFile: auditFilePath];
}

- (void) loadResults;
{
    NSString *auditFilePath = [self auditFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath: auditFilePath]) {
        NSDictionary *savedState = [NSKeyedUnarchiver unarchiveObjectWithFile: auditFilePath];
        [self willChangeValueForKey: @"auditStatusSummaryText"];
        [self setValue: [savedState objectForKey: @"audit list"] forKey: @"results"];
        [self setValue: [savedState objectForKey: @"audit date"] forKey: @"mAuditDateTime"];
        [self setValue: [savedState objectForKey: @"total driver count"] forKey: @"mTotalDriverCount"];
        [self didChangeValueForKey: @"auditStatusSummaryText"];
    }
}
@end

