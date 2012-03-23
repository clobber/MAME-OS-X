//
//  MameFileLogger.m
//  mameosx
//
//  Created by Dave Dribin on 1/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MameFileLogger.h"
#import "MamePreferences.h"
#include <unistd.h>


@implementation MameFileLogger

+ (id) defaultLogger;
{
    static MameFileLogger * logger = nil;
    if (logger == nil)
    {
        NSString * path = [self defaultPath];
        [self rotateLogAtPath: path rotations: kMameFileLoggerDefaultRotations];
        logger = [[MameFileLogger alloc] initWithPath: path];
    }
    return logger;
}

+ (NSString *) defaultPath;
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                          NSUserDomainMask, YES);
    NSAssert([paths count] > 0, @"Could not locate NSLibraryDirectory in user domain");
    
    NSString * library = [paths objectAtIndex: 0];
    NSString * libraryLogs = [library stringByAppendingPathComponent: @"Logs"];
    [fileManager createDirectoryAtPath: libraryLogs attributes: nil];
    NSString * mameLogs = [libraryLogs stringByAppendingPathComponent:
        [[NSBundle mainBundle] bundleIdentifier]];
    [fileManager createDirectoryAtPath: mameLogs attributes: nil];
    
    return [mameLogs stringByAppendingPathComponent: @"mameosx.log"];
}

+ (void) rotateLogAtPath: (NSString *) path rotations: (int) rotations;
{
    if (rotations < 1)
        return;
    
    // Name log files 0 through # rotatations - 1
    rotations--;
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * lastLog = [NSString stringWithFormat: @"%@.%d", path, rotations];
    if ([fileManager fileExistsAtPath: lastLog])
        [fileManager removeFileAtPath: lastLog handler: NULL];
    
    rotations--;
    int i;
    for (i = rotations; i >= 0; i--)
    {
        NSString * currentLog = [NSString stringWithFormat: @"%@.%d", path, i];
        NSString * rotatedLog = [NSString stringWithFormat: @"%@.%d", path, i+1];
        
        if ([fileManager fileExistsAtPath: currentLog])
            [fileManager movePath: currentLog toPath: rotatedLog handler: nil];
    }
    
    NSString * firstRotation = [NSString stringWithFormat: @"%@.0", path];
    if ([fileManager fileExistsAtPath: path])
        [fileManager movePath: path toPath: firstRotation handler: nil];
}

- (id) initWithPath: (NSString *) path;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    CFLocaleRef currentLocale = CFLocaleCopyCurrent();
    mDateFormatter = CFDateFormatterCreate(
        NULL, currentLocale, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
    CFStringRef customDateFormat = CFSTR("yyyy-MM-dd HH:mm:ss.SSS");
    CFDateFormatterSetFormat(mDateFormatter, customDateFormat);
    CFRelease(currentLocale);
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSString * directory = [path stringByDeletingLastPathComponent];
    [fileManager createDirectoryAtPath: directory attributes: nil];
    [fileManager createFileAtPath: path contents: nil attributes: nil];
    mFileHandle = [[NSFileHandle fileHandleForWritingAtPath: path] retain];
    
    mLogAllToConsole = [[MamePreferences standardPreferences] logAllToConsole];
    
    return self;
}

- (void)logWithLevel:(JRLogLevel)callerLevel_
			instance:(NSString*)instance_
				file:(const char*)file_
				line:(unsigned)line_
			function:(const char*)function_
			 message:(NSString*)message_;
{
    // Since this may get called frequently, use our own poo
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    @try
    {
        NSString * formattedMessage = [NSString stringWithFormat:
            @"%@:%u: %@",
            [[NSString stringWithUTF8String:file_] lastPathComponent],
            line_,
            message_];
        
        NSString * dateString = (NSString *)
            CFDateFormatterCreateStringWithAbsoluteTime
                (NULL, mDateFormatter, CFAbsoluteTimeGetCurrent());
        [dateString autorelease];
        
        NSString * finalMessage = [NSString stringWithFormat:
            @"%@ %@\n", dateString, formattedMessage];

        NSData * utf8Data = [finalMessage dataUsingEncoding: NSUTF8StringEncoding];
        [mFileHandle writeData: utf8Data];

        if ((callerLevel_ >= JRLogLevel_Warn) || mLogAllToConsole)
            NSLog(@"%@", formattedMessage);
    }
    @finally
    {
        [pool release];
    }
}

- (void) flushLogFile;
{
    [mFileHandle synchronizeFile];
}

@end
