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
//  GenericToolbarDataSource.m
//  GenericToolbar
//

#import "GenericToolbarDataSource.h"

static NSDictionary *defaultItems = nil;
static NSArray *defaultPaletteItemIdentifiers = nil;
static NSArray *defaultInitialItemIdentifiers = nil;
static NSArray *defaultSelectableItemIdentifiers = nil;
static NSArray *empty = nil;

/*!
 * @class GenericToolbarDataSource
 * Provides an NSCoding-compliant toolbar data source (known as a delegate to
 * NSToolbar). An instance of GenericToolbarDataSource is manipulated through
 * the GenericToolbar editor in Interface Builder. Data sources also have a
 * delegate that can override any or all of the toolbar delegate methods. (see
 * {@link NSToolbar}). Because the same data source is shared among toolbars,
 * calling <code>setDelegate:</code> on any GenericToolbar will affect <em>all</em>
 * of them. <br/>
 * Also remember that the real name of this class is ComBelkadanGenerictoolbar_ToolbarDataSource.
 * This shouldn't matter, because of the #define in the header file. However, just don't get
 * confused.
 */
@implementation GenericToolbarDataSource

+ (void)initialize
{
	empty = [NSArray new];
}

/*!
 * Returns the items that can be in a default toolbar. This is usually unused, unless a
 * completely new toolbar has just been created. Each item in the dictionary is a
 * @link GenericToolbarItem @/link.
 *
 * @see #defaultPaletteItemIdentifiers
 * @see #defaultInitialItemIdentifiers
 * @see #defaultSelectableItemIdentifiers
 * @functiongroup Default toolbar information
 */
+ (NSDictionary *)defaultItems
{
	if (defaultItems == nil) {
		GenericToolbarItem *customizeItem = [[GenericToolbarItem alloc] initWithItemIdentifier:NSToolbarCustomizeToolbarItemIdentifier];
		GenericToolbarItem *flexibleSpaceItem = [[GenericToolbarItem alloc] initWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier];
		GenericToolbarItem *fixedSpaceItem = [[GenericToolbarItem alloc] initWithItemIdentifier:NSToolbarSpaceItemIdentifier];
		GenericToolbarItem *separatorItem = [[GenericToolbarItem alloc] initWithItemIdentifier:NSToolbarSeparatorItemIdentifier];
		
		defaultItems = [[NSDictionary alloc] initWithObjectsAndKeys:customizeItem, NSToolbarCustomizeToolbarItemIdentifier,
																flexibleSpaceItem, NSToolbarFlexibleSpaceItemIdentifier,
																   fixedSpaceItem, NSToolbarSpaceItemIdentifier,
																	separatorItem, NSToolbarSeparatorItemIdentifier, nil];
		[customizeItem release];
		[flexibleSpaceItem release];
		[fixedSpaceItem release];
		[separatorItem release];
	}
	return defaultItems;
}

/*!
 * Returns the identifiers of the items on a default toolbar's customization palette.
 * This is usually unused, unless a completely new toolbar has just been created.
 * By default, these are NSToolbarCustomizeToolbarItemIdentifier,
 * NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, and
 * NSToolbarFlexibleSpaceItemIdentifier.
 *
 * @see #defaultItems
 * @see #defaultInitialItemIdentifiers
 * @see #defaultSelectableItemIdentifiers
 */
+ (NSArray *)defaultPaletteItemIdentifiers
{
	if (defaultPaletteItemIdentifiers == nil) {
		defaultPaletteItemIdentifiers = [[NSArray alloc] initWithObjects:NSToolbarCustomizeToolbarItemIdentifier,
																		 NSToolbarSeparatorItemIdentifier,
																		 NSToolbarSpaceItemIdentifier,
																		 NSToolbarFlexibleSpaceItemIdentifier, nil];
	}
	return defaultPaletteItemIdentifiers;
}
														 
/*!
 * Returns the identifiers of the items initially in a default toolbar (before user
 * customization). This is usually unused, unless a completely new toolbar has just
 * been created. By default, these are NSToolbarFlexibleSpaceItemIdentifier and
 * NSToolbarCustomizeToolbarItemIdentifier.
 *
 * @see #defaultItems
 * @see #defaultPaletteItemIdentifiers
 * @see #defaultSelectableItemIdentifiers
 */
+ (NSArray *)defaultInitialItemIdentifiers
{
	if (defaultInitialItemIdentifiers == nil) {
		defaultInitialItemIdentifiers = [[NSArray alloc] initWithObjects:NSToolbarFlexibleSpaceItemIdentifier, 
																		 NSToolbarCustomizeToolbarItemIdentifier, nil];
	}
	return defaultInitialItemIdentifiers;
}
														 
														 
/*!
 * Returns the identifiers of the selectable items in a default toolbar.
 * This is usually unused, unless a completely new toolbar has just been created.
 * By default, no items are selectable.
 *
 * @see #defaultItems
 * @see #defaultPaletteItemIdentifiers
 * @see #defaultInitialItemIdentifiers
 */
+ (NSArray *)defaultSelectableItemIdentifiers
{
	if (defaultSelectableItemIdentifiers == nil) {
		defaultSelectableItemIdentifiers = [empty retain];
	}
	return defaultSelectableItemIdentifiers;
}

#pragma mark -

/*!
 * Creates and returns a toolbar data source with the default palette, initial, 
 * and selectable items.
 *
 * @see #defaultItems
 * @see #defaultPaletteItemIdentifiers
 * @see #defaultInitialItemIdentifiers
 * @see #defaultSelectableItemIdentifiers
 * @functiongroup Creating a data source
 */
+ (GenericToolbarDataSource *)toolbarDataSource
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	Class thisClass = [self class];
	return [self initWithItemDictionary:[thisClass defaultItems]
					 paletteIdentifiers:[thisClass defaultPaletteItemIdentifiers]
					 initialIdentifiers:[thisClass defaultInitialItemIdentifiers]
				  selectableIdentifiers:[thisClass defaultSelectableItemIdentifiers]];
}

/*!
 * Convenience constructor; calls
 * @link initWithDictionary:paletteIdentifiers:initialIdentifiers:selectableIdentifiers: @/link
 * with no initial or selectable toolbar items. <code>items</code> must be an array
 * of NSToolbarItems, preferably instances of GenericToolbarItem.
 *
 * @see #initWithInitialItems:
 * @see #initWithItems:initialItemIdentifiers:
 * @see #initWithItemDictionary:paletteIdentifiers:initialIdentifiers:selectableIdentifiers:
 */
- (id)initWithItems:(NSArray *)items
{
	NSArray *identifiers = [items valueForKey:@"itemIdentifier"];
	return [self initWithItemDictionary:[NSDictionary dictionaryWithObjects:items forKeys:identifiers]
					 paletteIdentifiers:identifiers
					 initialIdentifiers:empty
				  selectableIdentifiers:empty];
}

/*!
 * Convenience constructor; calls
 * @link initWithDictionary:paletteIdentifiers:initialIdentifiers:selectableIdentifiers: @/link
 * with all items initially in the toolbar, and no selectable toolbar items. <code>items</code>
 * must be an array of NSToolbarItems, preferably instances of GenericToolbarItem.
 *
 * @see #initWithItems:
 * @see #initWithItems:initialItemIdentifiers:
 * @see #initWithItemDictionary:paletteIdentifiers:initialIdentifiers:selectableIdentifiers:
 */
- (id)initWithInitialItems:(NSArray *)items
{
	NSArray *identifiers = [items valueForKey:@"itemIdentifier"];
	return [self initWithItemDictionary:[NSDictionary dictionaryWithObjects:items forKeys:identifiers]
					 paletteIdentifiers:identifiers
					 initialIdentifiers:identifiers
				  selectableIdentifiers:empty];
}

/*!
 * Convenience constructor; calls
 * @link initWithDictionary:paletteIdentifiers:initialIdentifiers:selectableIdentifiers: @/link
 * with the given items in the toolbar, and no selectable toolbar items. <code>items</code> must
 * be an array of NSToolbarItems, preferably instances of GenericToolbarItem.
 * <code>initialIDs</code> must be an array of toolbar identifiers, in the form of NSStrings.
 *
 * @see #initWithItems:
 * @see #initWithInitialItems:
 * @see #initWithItemDictionary:paletteIdentifiers:initialIdentifiers:selectableIdentifiers:
 */
- (id)initWithItems:(NSArray *)items initialItemIdentifiers:(NSArray *)intialIDs
{
	NSArray *identifiers = [items valueForKey:@"itemIdentifier"];
	return [self initWithItemDictionary:[NSDictionary dictionaryWithObjects:items forKeys:identifiers]
					 paletteIdentifiers:identifiers
					 initialIdentifiers:intialIDs
				  selectableIdentifiers:empty];
}

/*!
 * This is the designated initializer for GenericToolbarDataSource, and returns a newly
 * initialized instance with the given data (see @link NSToolbar @/link 's delegate
 * documentation for more information). This class is usually only created by GenericToolbar
 * in Interface Builder; you should not have to worry about it yourself. <code>items</code>
 * is a dictionary mapping toolbar identifiers to instances of NSToolbarItem (preferably
 * GenericToolbarItems). The three arrays are lists of toolbar identifiers in the order you
 * want them to appear, though for <code>newSelectableIDs</code> it does not matter.
 */
- (id)initWithItemDictionary:(NSDictionary *)items
		  paletteIdentifiers:(NSArray *)newPaletteIDs
		  initialIdentifiers:(NSArray *)newInitialIDs
	   selectableIdentifiers:(NSArray *)newSelectableIDs
{
	self = [super init];
	if (self != nil) {
		allItems		= [items mutableCopy];
		paletteIDs		= [newPaletteIDs mutableCopy];
		initialIDs		= [newInitialIDs mutableCopy];
		selectableIDs	= [newSelectableIDs mutableCopy];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ([decoder respondsToSelector:@selector(allowsKeyedCoding)] &&
		[decoder allowsKeyedCoding] &&
		[decoder containsValueForKey:@"keyedCoding"]) {
		return [self initWithKeyedCoder:decoder];
		
	} else {
		return [self initWithUnkeyedCoder:decoder];
	}
}

/*!
 * Initializes a newly allocated instance from data in the keyed decoder.
 *
 * @functiongroup Initializing with a coder
 */
- (id)initWithKeyedCoder:(NSCoder *)decoder
{
	allItems		= [[decoder decodeObjectForKey:@"itemDictionary"]	mutableCopy];
	paletteIDs		= [[decoder decodeObjectForKey:@"paletteIDs"]		mutableCopy];
	initialIDs		= [[decoder decodeObjectForKey:@"initialIDs"]		mutableCopy];
	selectableIDs	= [[decoder decodeObjectForKey:@"selectableIDs"]	mutableCopy];
	
	return self;
}

/*!
 * Initializes a newly allocated instance from data in the unkeyed decoder.
 * If possible, use keyed archives to encode GenericToolbarDataSource; unkeyed
 * archives just aren't very safe.
 */
- (id)initWithUnkeyedCoder:(NSCoder *)decoder
{
	allItems		= [[decoder decodeObject] mutableCopy];
	paletteIDs		= [[decoder decodeObject] mutableCopy];
	initialIDs		= [[decoder decodeObject] mutableCopy];
	selectableIDs	= [[decoder decodeObject] mutableCopy];
	
	return self;
}

- (void)dealloc
{	
	[allItems release];
	[paletteIDs release];
	[initialIDs release];
	[selectableIDs release];
		
	[super dealloc];
}

#pragma mark -

- (void)encodeWithCoder:(NSCoder *)coder
{
//	[super encodeWithCoder:coder]; // NSObject has does not comply to NSCoding

	if ([coder respondsToSelector:@selector(allowsKeyedCoding)] &&
		[coder allowsKeyedCoding]) {
		[self encodeWithKeyedCoder:coder];

	} else {			
		[self encodeWithUnkeyedCoder:coder];
	}
}

/*!
 * Encodes the receiver into a keyed archive using coder. Also encodes a boolean flag under
 * the key <code>@"keyedCoding"</code>, signifying that this is a keyed archive.
 *
 * @functiongroup Encoding with a coder
 */
- (void)encodeWithKeyedCoder:(NSCoder *)coder
{
	[coder encodeObject:allItems forKey:@"itemDictionary"];
	[coder encodeObject:paletteIDs forKey:@"paletteIDs"];
	[coder encodeObject:initialIDs forKey:@"initialIDs"];
	[coder encodeObject:selectableIDs forKey:@"selectableIDs"];
	
	[coder encodeBool:YES forKey:@"keyedCoding"]; // Keyed archive flag
}

/*!
 * Encodes the receiver into an unkeyed archive using coder. If possible, use keyed
 * archives to encode GenericToolbar; unkeyed archives just aren't very safe.
 */
- (void)encodeWithUnkeyedCoder:(NSCoder *)coder
{
	[coder encodeObject:allItems];
	[coder encodeObject:paletteIDs];
	[coder encodeObject:initialIDs];
	[coder encodeObject:selectableIDs];
}

#pragma mark -

/*!
 * Returns the receiver’s delegate.
 *
 * @see #setDelegate:
 * @functiongroup Setting the data source's delegate
 */
- (id)delegate
{
	return delegate;
}

/*!
 * Sets the receiver’s delegate to <code>newDelegate</code>. Data source delegates
 * perform the same functions as normal toolbar delegates, but they are shared by
 * every toolbar using the receiver as a data source. The terminology is confusing,
 * but basically a data source delegate has the chance to change any of the data
 * source's data-providing methods by implementing them separately, in which case
 * the delegate's version will be used.
 *
 * @see #delegate
 */
- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate; // Delegates not retained
}

#pragma mark -

/*!
 * Returns the items that can be in the toolbar, stored by their identifiers.
 *
 * @see #paletteItemIDs
 * @see #initialItemIDs
 * @see #selectableItemIDs
 * @functiongroup Getting toolbar item information
 */
- (NSDictionary *)itemDictionary
{
	return allItems;
}

/*!
 * Returns the identifiers of the toolbar items that show up in the customization
 * palette (in order). This includes every possible toolbar item that can be used
 * in the toolbar.
 *
 * @see #itemDictionary
 * @see #initialItemIDs
 * @see #selectableItemIDs
 */
- (NSArray *)paletteItemIDs
{
	return paletteIDs;
}

/*!
 * Returns the identifiers of the toolbar items that initially show up in the
 * toolbar (in order). All of this identifiers must be keys in <code>itemDictionary</code>.
 *
 * @see #itemDictionary
 * @see #paletteItemIDs
 * @see #selectableItemIDs
 */
- (NSArray *)initialItemIDs
{
	return initialIDs;
}

/*!
 * Returns the identifiers of the toolbar items that are selectable (in no
 * particular order). All of this identifiers must be keys in <code>itemDictionary</code>.
 *
 * @see #itemDictionary
 * @see #paletteItemIDs
 * @see #initialItemIDs
 */
- (NSArray *)selectableItemIDs
{
	return selectableIDs;
}

/*!
 * Returns <code>YES</code> if <code>item</code> is in this toolbar, <code>NO</code>
 * if not. A return value of <code>YES</code> does not mean that the item is visible.
 *
 * @see #containsItemWithIdentifier:
 * @see #itemWithIdentifer:
 */
- (BOOL)containsItem:(GenericToolbarItem *)item
{
	return ([allItems objectForKey:[item itemIdentifier]] != nil);
}

/*!
 * Returns <code>YES</code> if an item with the identifier <code>itemID</code> is
 * in this toolbar, <code>NO</code> if not. A return value of <code>YES</code>
 * does not mean that the item is visible.
 *
 * @see #containsItem:
 * @see #itemWithIdentifer:
 */
- (BOOL)containsItemWithIdentifier:(NSString *)itemID
{
	return ([allItems objectForKey:itemID] != nil);
}

/*!
 * Returns the item with the identifier <code>itemID</code>, or <code>nil</code>
 * if that item is not in the toolbar (although it does not have to be visible).
 *
 * @see #containsItem:
 * @see #containsItemWithIdentifier:
 */
- (GenericToolbarItem *)itemWithIdentifier:(NSString *)itemID
{
	return [allItems objectForKey:itemID];
}

#pragma mark -

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
//	NSLog(@"toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar: -> %@", itemIdentifier);
	NSToolbarItem *item = nil;
	if (delegate != nil && [delegate respondsToSelector:_cmd])
		item = [delegate toolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
		
	if (item == nil)
		item = [[[self itemWithIdentifier:itemIdentifier] copy] autorelease];
	
	return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
//	NSLog(@"toolbarAllowedItemIdentifiers: -> %@", toolbar);
	if (delegate != nil && [delegate respondsToSelector:_cmd])
		return [delegate toolbarAllowedItemIdentifiers:toolbar];
	else
		return paletteIDs;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
//	NSLog(@"toolbarDefaultItemIdentifiers: -> %@", toolbar);
	if (delegate != nil && [delegate respondsToSelector:_cmd])
		return [delegate toolbarDefaultItemIdentifiers:toolbar];
	else
		return initialIDs;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
//	NSLog(@"toolbarSelectableItemIdentifiers: -> %@", toolbar);
	if (delegate != nil && [delegate respondsToSelector:_cmd])
		return [delegate toolbarSelectableItemIdentifiers:toolbar];
	else
		return selectableIDs;
}

- (void)toolbarWillAddItem:(NSNotification *)note
{
//	NSLog(@"toolbarWillAddItem: %@", [[note object] _items]);
	if (delegate != nil && [delegate respondsToSelector:_cmd])
		[delegate toolbarWillAddItem:note];
}

- (void)toolbarDidRemoveItem:(NSNotification *)note
{
//	NSLog(@"toolbarDidRemoveItem:");
	if (delegate != nil && [delegate respondsToSelector:_cmd])
		[delegate toolbarDidRemoveItem:note];
}

@end
