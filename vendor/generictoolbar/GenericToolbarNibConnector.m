/******************************************************************************
 Copyright (c) 2005-2006 Jordy Rose
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 Except as contained in this notice, the name(s) of the above copyright holders
 shall not be used in advertising or otherwise to promote the sale, use or other
 dealings in this Software without prior authorization.
*******************************************************************************/

//
//  GenericToolbarNibConnector.m
//  GenericToolbar
//
#import "GenericToolbarNibConnector.h"

static NSMutableSet *toolbarsWithCopies = nil;

/*!
 * @class GenericToolbarNibConnector
 * Used to make sure that a toolbar is not connected to more than one window. If
 * it is already in use, a copy of the toolbar with the same data source is used
 * instead. This should be totally transparent; you should never need to worry
 * about this class. It will only be used when you connect the <b>toolbar</b>
 * outlet of a window to an instance of <code>GenericToolbar</code>. <br/>
 * Also remember that the real name of this class is ComBelkadanGenerictoolbar_ToolbarNibConnector.
 * This shouldn't matter, because of the #define in the header file. However, just
 * don't get confused.
 */
@implementation GenericToolbarNibConnector
+ (void)initialize
{
	toolbarsWithCopies = (NSMutableSet *) CFSetCreateMutable(NULL, 0, NULL); // Non-retaining set
}

- (void)establishConnection
{
	GenericToolbar *toolbar = [self destination];
	if ([toolbarsWithCopies containsObject:toolbar])
		toolbar = [toolbar copy];
	else
		[toolbarsWithCopies addObject:[toolbar retain]];
	
	NSWindow *window = [self source];
	if ([[self label] isEqualToString:@"toolbar"]) {
		[window performSelector:@selector(setToolbar:) withObject:toolbar afterDelay:0];
	} else {
		[super establishConnection];
	}
	
	[toolbar release];
}
@end