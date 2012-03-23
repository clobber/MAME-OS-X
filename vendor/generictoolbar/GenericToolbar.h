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
//  GenericToolbar.h
//  GenericToolbar
//

#import <Cocoa/Cocoa.h>
#import "GenericToolbarItem.h"
#import "GenericToolbarDataSource.h"

#define GenericToolbar ComBelkadanGenerictoolbar_GenericToolbar

@interface GenericToolbar : NSToolbar <NSCoding, NSCopying>
{
	id dataSource;
	NSString *identifier;
	BOOL paletteVisible;
	BOOL showsBaseline;
}

- (id)initWithIdentifier:(NSString *)givenID;
- (id)initWithIdentifier:(NSString *)givenID dataSource:(id)givenDataSource;
- (id)initWithCoder:(NSCoder *)decoder;
- (id)initWithKeyedCoder:(NSCoder *)decoder;
- (id)initWithUnkeyedCoder:(NSCoder *)decoder;

- (id)finishCodedInitWithSizeMode:(NSToolbarSizeMode)sizeMode
					  displayMode:(NSToolbarDisplayMode)displayMode
			  allowsCustomization:(BOOL)allowsCustomization
						autosaves:(BOOL)autosaves
					showsBaseline:(BOOL)showsBaseline
						  visible:(BOOL)isVisible;

- (void)encodeWithCoder:(NSCoder *)coder;
- (void)encodeWithKeyedCoder:(NSCoder *)coder;
- (void)encodeWithUnkeyedCoder:(NSCoder *)coder;

- (id)dataSource;
- (void)setDataSource:(id)newDataSource;

@end

// Stop compiler warnings about scalar/pointer conversions
// BUT we let the "may not respond" warnings through...they're actually important
// since these methods *aren't* implemented on 10.3
#define TigerToolbar ComBelkadanGenerictoolbar_TigerToolbar
@protocol TigerToolbar
- (BOOL)showsBaselineSeparator;
- (void)setShowsBaselineSeparator:(BOOL)showsBaseline;
@end 