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

@interface MameFileManager : NSObject
{
}

+ (MameFileManager *) defaultFileManager;

- (NSString *) resolveAlias: (NSString *) path;

#pragma mark -
#pragma mark MAME OSD API
   
- (file_error) osd_open: (const char *) path
                  flags: (UINT32) openflags
                   file: (osd_file **) file
               filesize: (UINT64 *) filesize;

- (file_error) osd_close: (osd_file *) file;

- (file_error) osd_read: (osd_file *) file
                 buffer: (void *) buffer
                 offset: (UINT64) offset
                 length: (UINT32) length
                 actual: (UINT32 *) actual;

- (file_error) osd_write: (osd_file *) file
                  buffer: (const void *) buffer
                  offset: (UINT64) offset
                  length: (UINT32) length
                  actual: (UINT32 *) actual;

- (file_error) osd_rmfile: (const char *) filename;

- (int) osd_is_absolute_path: (const char *) path;


@end
