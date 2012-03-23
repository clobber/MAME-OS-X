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
//  GenericToolbarDataSource.h
//  GenericToolbar
//

#import <Cocoa/Cocoa.h>
#import "GenericToolbarItem.h"

#define GenericToolbarDataSource ComBelkadanGenerictoolbar_ToolbarDataSource

@interface GenericToolbarDataSource : NSObject <NSCoding> {
	IBOutlet id delegate;
		
	NSMutableArray *paletteIDs;
	NSMutableArray *initialIDs;
	NSMutableArray *selectableIDs;
	
	NSMutableDictionary *allItems;
}

+ (NSDictionary *)defaultItems;
+ (NSArray *)defaultPaletteItemIdentifiers;
+ (NSArray *)defaultInitialItemIdentifiers;
+ (NSArray *)defaultSelectableItemIdentifiers;

+ (GenericToolbarDataSource *)toolbarDataSource;
- (id)initWithItems:(NSArray *)items;
- (id)initWithInitialItems:(NSArray *)items;
- (id)initWithItems:(NSArray *)items initialItemIdentifiers:(NSArray *)intialIDs;

- (id)initWithItemDictionary:(NSDictionary *)items
		  paletteIdentifiers:(NSArray *)newPaletteIDs
		  initialIdentifiers:(NSArray *)newInitialIDs
	   selectableIdentifiers:(NSArray *)newSelectableIDs;

- (id)initWithKeyedCoder:(NSCoder *)decoder;
- (id)initWithUnkeyedCoder:(NSCoder *)decoder;
- (void)encodeWithKeyedCoder:(NSCoder *)coder;
- (void)encodeWithUnkeyedCoder:(NSCoder *)coder;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;
	   
- (NSDictionary *)itemDictionary;
- (NSArray *)paletteItemIDs;
- (NSArray *)initialItemIDs;
- (NSArray *)selectableItemIDs;
- (BOOL)containsItem:(GenericToolbarItem *)item;
- (BOOL)containsItemWithIdentifier:(NSString *)itemID;
- (GenericToolbarItem *)itemWithIdentifier:(NSString *)itemID;

// Implement these in a delegate class to handle toolbar behavior. If not implemented by a delegate, these will be handled by the toolbar.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar;
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar;

// Implement these in a delegate class to handle toolbar behavior. If not implemented by a delegate, these will be ignored.
- (void)toolbarWillAddItem:(NSNotification *)note;
- (void)toolbarDidRemoveItem:(NSNotification *)note;

@end
