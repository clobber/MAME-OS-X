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

#import "VersionChecker.h"
#import "MameVersion.h"
#import "JRLog.h"

@interface VersionChecker (Private)

- (void) setUpdateInProgress: (BOOL) updateInProgress;

- (void) downloadVersionInBackground: (NSString *) versionUrl;

- (void) downloadVersionFailedForUrl: (NSString *) versionUrl;

- (void) downloadVersionComplete: (NSDictionary *) versionDictionary;

- (void) displayNewVersionAvailableDialog;

- (void) displayUpToDateDialog;

@end


@implementation VersionChecker

- (id) init;
{
    if ([super init] == nil)
        return nil;
    
    mUpdateInProgress = NO;
    mVerbose = NO;
   
    return self;
}

- (NSString *) versionUrl;
{
    return mVersionUrl;
}

- (void) setVersionUrl: (NSString *) versionUrl;
{
    [versionUrl retain];
    [mVersionUrl release];
    mVersionUrl = versionUrl;
}

- (BOOL) updateInProgress;
{
    return mUpdateInProgress;
}

- (IBAction) checkForUpdates: (id) sender;
{
    [self checkForUpdatesAndNotify: YES];
}

- (void) checkForUpdatesInBackground;
{
    [self checkForUpdatesAndNotify: NO];
}

- (void) checkForUpdatesAndNotify: (BOOL) notify;
{
    if (mUpdateInProgress == YES)
    {
        JRLogWarn(@"Update already in progress");
        return;
    }
    
    [self setUpdateInProgress: YES];
    mVerbose = notify;
	[NSThread detachNewThreadSelector: @selector(downloadVersionInBackground:)
                             toTarget: self withObject: mVersionUrl];
}

@end

@implementation VersionChecker (Private)

- (void) setUpdateInProgress: (BOOL) updateInProgress;
{
    mUpdateInProgress = updateInProgress;
}

- (void) downloadVersionInBackground: (NSString *) versionUrl;
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSDictionary * plist = [[NSDictionary alloc] initWithContentsOfURL:
        [NSURL URLWithString: versionUrl]];
    if (!plist)
    {
        [self performSelectorOnMainThread: @selector(downloadVersionFailedForUrl:)
                               withObject: versionUrl
                            waitUntilDone: NO];
    }
    else
    {
        [self performSelectorOnMainThread: @selector(downloadVersionComplete:)
                               withObject: plist
                            waitUntilDone: NO];
    }
    
    [pool release];
}
    

- (void) downloadVersionFailedForUrl: (NSString *) versionUrl;
{
    if (mVerbose)
    {
        NSAlert * alert = [[NSAlert alloc] init];
        [alert setMessageText: @"Could not get version information."];
        [alert setInformativeText:
            @"An error occured while trying to retrieve the current version."];
        [alert setAlertStyle: NSWarningAlertStyle];
        [alert addButtonWithTitle: @"OK"];
        [alert runModal];
        [alert release];
    }
    JRLogWarn(@"Couldn't access version info");
    JRLogWarn(@"versionUrl: %@", versionUrl);
    [self setUpdateInProgress: NO];
    return;
}

- (void) downloadVersionComplete: (NSDictionary *) versionDictionary;
{
    [versionDictionary autorelease];
    NSBundle * myBundle = [NSBundle mainBundle];
    NSString * myId = [myBundle bundleIdentifier];
    NSDictionary * infoDict = [myBundle infoDictionary];
    mMyVersion = [MameVersion version];
    mMyVersionString = [MameVersion marketingVersion];
    
    NSDictionary * versionDict = [versionDictionary valueForKey: myId];
    mCurrentVersion = [versionDict valueForKey:@"version"];
    mCurrentVersionString = [versionDict valueForKey:@"versionString"];
    mDownloadUrl = [versionDict valueForKey:@"downloadUrl"];
    mInfoUrl = [versionDict valueForKey:@"infoUrl"];

    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * skippedVersion = [defaults stringForKey: @"SkippedVersion"];
    
    NSComparisonResult myOrder = [MameVersion compareVersion: mMyVersion
                                                   toVersion: mCurrentVersion];

    NSComparisonResult skippedOrder =
        [MameVersion compareVersion: skippedVersion
                          toVersion: mCurrentVersion];

    JRLogInfo(@"%@: my version: %@, current version: %@, skipped version: %@, "
              @"my order: %d, skipped order: %d",
              myId, mMyVersion, mCurrentVersion, skippedVersion,
              myOrder, skippedOrder);
    
    if (myOrder == NSOrderedAscending)
    {
        if ((skippedOrder == NSOrderedAscending) || mVerbose)
        {
            [self displayNewVersionAvailableDialog];
        }
    }
    else if (mVerbose)
    {
        [self displayUpToDateDialog];
    }
    [self setUpdateInProgress: NO];
}

- (void) displayNewVersionAvailableDialog;
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    NSString * message = [NSString stringWithFormat:
        @"MAME OS X %@ is available (you have %@).  "
        @"Would you like to download it now?",
        mCurrentVersionString, mMyVersionString];
    NSAlert * alert = [[NSAlert alloc] init];
    [alert setMessageText: @"A new version of MAME OS X is available."];
    [alert setInformativeText: message];
    [alert setAlertStyle: NSInformationalAlertStyle];
    [alert addButtonWithTitle: @"Download..."];
    [alert addButtonWithTitle: @"More info..."];
    [alert addButtonWithTitle: @"Skip this version"];
    [alert addButtonWithTitle: @"Remind later"];
    int result = [alert runModal];
    if (result == NSAlertFirstButtonReturn)
    {
        [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: mDownloadUrl]];
    }
    else if (result == NSAlertSecondButtonReturn)
    {
        [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: mInfoUrl]];
    }
    else if (result == NSAlertThirdButtonReturn)
    {
        [defaults setObject: mCurrentVersion forKey: @"SkippedVersion"];
    }
    else if (result == NSAlertThirdButtonReturn + 1)
    {
        [defaults setObject: nil forKey: @"SkippedVersion"];
    }
    [defaults synchronize];
    [alert release];
}

- (void) displayUpToDateDialog;
{
    NSString * message = [NSString stringWithFormat:
        @"Version %@ of MAME OS X is the most current version.",
        mCurrentVersionString];
    NSAlert * alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Your version of MAME OS X is up to date."];
    [alert setInformativeText: message];
    [alert setAlertStyle: NSInformationalAlertStyle];
    [alert addButtonWithTitle: @"OK"];
    [alert runModal];
    [alert release];
}

@end
