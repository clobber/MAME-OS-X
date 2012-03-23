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
//  GenericToolbarItem.h
//  GenericToolbar
//

#import <Cocoa/Cocoa.h>

#define GenericToolbarItem ComBelkadanGenerictoolbar_GenericToolbarItem
//#define DuplicatableNSToolbarItem ComBelkadanGenerictoolbar_DuplicatableNSToolbarItem

@interface GenericToolbarItem : NSToolbarItem <NSCoding> {
	NSString *identifier;
	BOOL allowsDuplicates;
	BOOL enabled;
}
- (id)initWithItemIdentifier:(NSString *)givenID;
- (id)initWithCoder:(NSCoder *)decoder;
- (id)initWithKeyedCoder:(NSCoder *)decoder;
- (id)initWithUnkeyedCoder:(NSCoder *)decoder;
- (id)finishCodedInitWithTag:(int)tag imageName:(NSString *)imageName visibilityPriority:(int)visibilityPriority autovalidates:(BOOL)autovalidates;

- (void)encodeWithCoder:(NSCoder *)coder;
- (void)encodeWithKeyedCoder:(NSCoder *)coder;
- (void)encodeWithUnkeyedCoder:(NSCoder *)coder;

- (void)setAllowsDuplicatesInToolbar:(BOOL)changedAllowsDuplicates;

- (NSToolbarItem *)asNSToolbarItem;
- (BOOL)shouldCreateNSToolbarItem;

@end

/*
@interface DuplicatableNSToolbarItem : NSToolbarItem { }
@end
*/

// Stop compiler warnings about scalar/pointer conversions
// BUT we let the "does not implement" warnings through...they're actually important
#define TigerToolbarItem ComBelkadanGenerictoolbar_TigerToolbarItem
@protocol TigerToolbarItem
- (BOOL)autovalidates;
- (void)setAutovalidates:(BOOL)autovalidates;
- (int)visibilityPriority;
- (void)setVisibilityPriority:(int)visibilityPriority;
@end 