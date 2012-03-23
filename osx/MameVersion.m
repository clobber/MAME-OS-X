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

#import "MameVersion.h"


@implementation MameVersion

+ (NSString *) marketingVersion;
{
    NSBundle * mainBundle = [NSBundle mainBundle];
    return [[mainBundle infoDictionary] objectForKey: @"CFBundleShortVersionString"];
}

+ (NSString *) version;
{
    NSBundle * mainBundle = [NSBundle mainBundle];
    return [[mainBundle infoDictionary] objectForKey: @"CFBundleVersion"];
}

+ (BOOL) isTiny;
{
    NSString * processName = [[NSProcessInfo processInfo] processName];
    NSRange range = [processName rangeOfString: @"tiny"];
    if (range.location == NSNotFound)
        return NO;
    else
        return YES;
}

+ (NSComparisonResult) compareVersion: (NSString *) version1
                            toVersion: (NSString *) version2;
{
    if (version1 == nil)
        return NSOrderedAscending;
    
    NSArray * version1Parts = [version1 componentsSeparatedByString: @"."];
    NSArray * version2Parts = [version2 componentsSeparatedByString: @"."];
    NSComparisonResult result = NSOrderedSame;
    unsigned i;
    for (i = 0; i < [version1Parts count]; i++)
    {
        NSString * part1String = [version1Parts objectAtIndex: i];
        NSString * part2String = [version2Parts objectAtIndex: i];
        int part1 = [part1String intValue];
        int part2 = [part2String intValue];
        if (part1 < part2)
        {
            result = NSOrderedAscending;
            break;
        }
        if (part1 > part2)
        {
            result = NSOrderedDescending;
            break;
        }
        
    }
    
    return result;
}

@end
