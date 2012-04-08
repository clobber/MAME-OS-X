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

#include <sys/types.h>
#include <sys/stat.h>
#import "osdepend.h"
#import "MameFileManager.h"
#import "JRLog.h"
#import "osd_osx.h"

struct _osd_file
{
    FILE * fileHandle;
};

static MameFileManager * sInstance = nil;

@interface MameFileManager (Private)

- (void) createDirectoriesForComponents: (NSMutableArray *) components
                       currentDirectory: (NSString *) currentDirectory;

@end

@implementation MameFileManager

+ (void) initialize;
{
    osx_osd_core_init();
}

+ (MameFileManager *) defaultFileManager;
{
    if (sInstance == nil)
        sInstance = [[MameFileManager alloc] init];
    return sInstance;
}

- (NSString *) resolveAlias: (NSString *) path
{
    NSString *resolvedPath = [[NSFileManager defaultManager] currentDirectoryPath];
    if ([path isAbsolutePath])
        resolvedPath = @"/";
        
    //Parse the given path and if any part is an alias return the resolved path
    CFURLRef url;
    
    //As the given path could contain an alias anywhere we need to parse each
    //element of the path individually and compose the result
    NSArray *pathElements = [path componentsSeparatedByString: @"/"];
    NSEnumerator *pathEnum = [pathElements objectEnumerator];
    id element;
    
    while (element = [pathEnum nextObject])
    {
        //If this is an absolute path then the first element of the array will be empty
        if ((NSString *)[element length] > 0)
        {
            resolvedPath = [resolvedPath stringByAppendingPathComponent: element];
            //NSLog(@"Trying to parse: %@", resolvedPath);
            
            NSString *tmpPath = nil;
            url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)resolvedPath, kCFURLPOSIXPathStyle, YES);
            if (url != NULL)
            {
                FSRef fsRef;
                if (CFURLGetFSRef(url, &fsRef))
                {
                    Boolean targetIsFolder, wasAliased;
                    if (FSResolveAliasFile (&fsRef, true, &targetIsFolder, &wasAliased) == noErr && wasAliased)
                    {
                        CFURLRef resolvedUrl = CFURLCreateFromFSRef(NULL, &fsRef);
                        if (resolvedUrl != NULL)
                        {
                            tmpPath = (NSString*) CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle);
                            CFRelease(resolvedUrl);
                        }
                    }
                }
                CFRelease(url);
            }
            if (tmpPath != nil)
                resolvedPath = tmpPath;
        }
    }

    if (resolvedPath == nil)    //Resolved path SHOULD always be sommething but it doesn't hurt to ensure we never return nil!
        resolvedPath = [[NSString alloc] initWithString:path];
    return resolvedPath;
}

#pragma mark -
#pragma mark MAME OSD API

- (file_error) osd_open: (const char *) path
                  flags: (UINT32) openflags
                   file: (osd_file **) file
               filesize: (UINT64 *) filesize;
{
    JRLogDebug(@"osd_open: path: %s, flags: 0x%08x", path, openflags);
    NSAssert(path != 0, @"path is NULL");
    NSString * nsPath = [NSString stringWithUTF8String: path];
    nsPath = [self resolveAlias: nsPath];
    BOOL readFlag = ((openflags & OPEN_FLAG_READ) != 0);
    BOOL writeFlag = ((openflags & OPEN_FLAG_WRITE) != 0);
    BOOL createFlag = ((openflags & OPEN_FLAG_CREATE) != 0);
    BOOL createPathsFlag = ((openflags & OPEN_FLAG_CREATE_PATHS) != 0);
    
    if (createPathsFlag)
    {
        NSString * directory = [nsPath stringByDeletingLastPathComponent];
        NSMutableArray * components =
            [[[directory pathComponents] mutableCopy] autorelease];
        [self createDirectoriesForComponents: components
                            currentDirectory: @""];
    }
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSDictionary * fileAttributes =
        [fileManager fileAttributesAtPath: nsPath traverseLink: YES];
    BOOL fileExists = (fileAttributes != nil);

    if (!fileExists && !createFlag)
    {
        JRLogDebug(@"osd_open: not found");
        return FILERR_NOT_FOUND;
    }
    
    const char * mode;
    if (readFlag && !writeFlag)
        mode = "rb";
    else if (readFlag && writeFlag && !createFlag)
        mode = "rb+";
    else if (readFlag && writeFlag && createFlag)
        mode = "wb+";
    else if (!readFlag && writeFlag)
        mode = "wb";
    else
    {
        JRLogError(@"osd_open: Invalid mode: 0x%08X, path: %@", openflags, nsPath);
        return FILERR_FAILURE;
    }
    
    FILE * handle = fopen([nsPath UTF8String], mode);
    if (handle == 0)
    {
        return FILERR_FAILURE;
    }
    
    *file = (osd_file*)malloc(sizeof(*file));
    if (*file == 0)
    {
        fclose(handle);
        return FILERR_OUT_OF_MEMORY;
    }
    
    (*file)->fileHandle = handle;
    if (filesize != NULL)
        *filesize = [fileAttributes fileSize];
    JRLogDebug(@"osd_open success, path: %@, mode: %s", nsPath, mode);
    return FILERR_NONE;
}

- (file_error) osd_close: (osd_file *) file;
{
    NSAssert(file != 0, @"file should not be null");
    int rc = fclose(file->fileHandle);
    free(file);
    if (rc == 0)
        return FILERR_NONE;
    else
        return FILERR_FAILURE;
}

- (file_error) osd_read: (osd_file *) file
                 buffer: (void *) buffer
                 offset: (UINT64) offset
                 length: (UINT32) length
                 actual: (UINT32 *) actual;
{
    fseek(file->fileHandle, offset, SEEK_SET);
    size_t rc = fread(buffer, 1, length, file->fileHandle);
    if ((rc != length) && (ferror(file->fileHandle)))
    {
        clearerr(file->fileHandle);
        NSLog(@"osd_read error");
        return FILERR_FAILURE;
    }

    *actual = rc;
    return FILERR_NONE;
}

- (file_error) osd_write: (osd_file *) file
                  buffer: (const void *) buffer
                  offset: (UINT64) offset
                  length: (UINT32) length
                  actual: (UINT32 *) actual;
{
    fseek(file->fileHandle, offset, SEEK_SET);
    size_t rc = fwrite(buffer, 1, length, file->fileHandle);
    if ((rc != length) && (ferror(file->fileHandle)))
    {
        clearerr(file->fileHandle);
        NSLog(@"osd_read error");
        return FILERR_FAILURE;
    }
    
    *actual = rc;
    return FILERR_NONE;
}

- (file_error) osd_rmfile: (const char *) filename;
{
    JRLogDebug(@"osd_rmfile: filename: %s", filename);
    NSAssert(filename != 0, @"path is NULL");
    NSString * nsPath = [NSString stringWithUTF8String: filename];
    BOOL succeeded =
        [[NSFileManager defaultManager] removeFileAtPath: nsPath handler: nil];
    if (!succeeded)
        return FILERR_FAILURE;
    else
        return FILERR_NONE;
}

- (int) osd_is_absolute_path: (const char *) path;
{
    JRLogDebug(@"osd_is_absolute_path: path: %s", path);
    NSAssert(path != 0, @"path is NULL");
    NSString * nsPath = [NSString stringWithUTF8String: path];
    return [nsPath isAbsolutePath];
}

@end

@implementation MameFileManager (Private)

- (void) createDirectoriesForComponents: (NSMutableArray *) components
                       currentDirectory: (NSString *) currentDirectory;
{
    if ([components count] == 0)
        return;
    
    NSString * nextComponent = [components objectAtIndex: 0];
    [components removeObjectAtIndex: 0];
    NSString * nextDirectory =
        [currentDirectory stringByAppendingPathComponent: nextComponent];
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fm fileExistsAtPath: nextDirectory isDirectory: &isDirectory])
    {
        if (!isDirectory)
        {
            JRLogWarn(@"Path is not a directory: %@", nextDirectory);
            return;
        }
    }
    else
    {
        BOOL success = [fm createDirectoryAtPath: nextDirectory
                                      attributes: nil];
        if (!success)
        {
            JRLogWarn(@"Could not create directory: %@", nextDirectory);
            return;
        }
    }
    [self createDirectoriesForComponents: components
                        currentDirectory: nextDirectory];
}

@end


