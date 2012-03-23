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
//  GenericToolbar.m
//  GenericToolbar
//

#import "GenericToolbar.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_3
	#define TOOLBAR_SIZE_MODE_DEFAULT 0
#else
	#define TOOLBAR_SIZE_MODE_DEFAULT NSToolbarSizeModeDefault
#endif

static unsigned int untitledToolbarCount = 0;
static NSString * const genericTitle = @"ComBelkadanGenerictoolbar_toolbarID_%u";

/*!
 * @class GenericToolbar
 * Finally, an NSCoding-compliant subclass of NSToolbar! GenericToolbar is a self-managed
 * toolbar, keeping track of its own items, and easy to create in Interface Builder. Just
 * connect the toolbar outlet of NSWindow to your instance of GenericToolbar. Don't forget
 * to include the set of GenericToolbar header and implementation files in your project. <br/>
 * Also remember that the real name of this class is ComBelkadanGenerictoolbar_GenericToolbar.
 * This shouldn't matter, because of the #define in the header file. However, just don't get
 * confused in Interface Builder.
 *
 * @version 1.0
 */
@implementation GenericToolbar

- (id)initWithIdentifier:(NSString *)givenID
{
	return [self initWithIdentifier:givenID dataSource:nil];
}

/*!
 * The designated initializer for GenericToolbar. Besides creating the toolbar, this method
 * also sets up its data source, which takes care of the item-providing methods of the
 * toolbar delegate.
 *
 * @functiongroup Initializing GenericToolbar
 */
- (id)initWithIdentifier:(NSString *)givenID dataSource:(id)givenDataSource
{
	self = [super initWithIdentifier:givenID];
	if (self != nil) {
		dataSource = (givenDataSource == nil) ? [GenericToolbarDataSource new] : [givenDataSource retain];
		identifier = [[self identifier] retain];
		paletteVisible = YES;
		showsBaseline = YES;
		[super setDelegate:dataSource];
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
 * If the encoded data does not contain an identifier string, a default one
 * will be created for this toolbar.
 *
 * @functiongroup Initializing with a coder
 */
- (id)initWithKeyedCoder:(NSCoder *)decoder
{
	int32_t sizeAsInt, displayModeAsInt;
	BOOL allowsCustomization, autosaves;
	
	NSString *codedID = [[decoder decodeObjectForKey:@"identifier"] retain];
	
	if (codedID == nil || [codedID isEqualToString:@""]) {
		[codedID release];
		codedID = [[NSString alloc] initWithFormat:genericTitle, untitledToolbarCount++];
	}

	self = [super initWithIdentifier:codedID];
	if (self == nil) {
		[codedID release];
		return self;
	}
	
	identifier = codedID; // Retain already taken care of.
		
	dataSource = [[decoder decodeObjectForKey:@"dataSource"] retain];
	
	allowsCustomization	= [decoder decodeBoolForKey:@"allowsCustomization"];
	autosaves			= [decoder decodeBoolForKey:@"autosaves"];
	paletteVisible		= [decoder decodeBoolForKey:@"visible"];
	showsBaseline		= [decoder decodeBoolForKey:@"showsBaselineSeparator"];
	
	sizeAsInt			= [decoder decodeInt32ForKey:@"sizeMode"];
	displayModeAsInt	= [decoder decodeInt32ForKey:@"displayMode"];
	
	return [self finishCodedInitWithSizeMode:(NSToolbarSizeMode)sizeAsInt
								 displayMode:(NSToolbarDisplayMode)displayModeAsInt
						 allowsCustomization:allowsCustomization
								   autosaves:autosaves
							   showsBaseline:showsBaseline
									 visible:paletteVisible];
}

/*!
 * Initializes a newly allocated instance from data in the unkeyed decoder.
 * If the encoded data does not contain an identifier string, a default one
 * will be created for this toolbar. Also, if there is no type that is 32 bits
 * wide, the size mode and display mode cannot be decoded, in which case the
 * default values will be substituted. If possible, use keyed archives to encode
 * GenericToolbar; unkeyed archives just aren't very safe.
 */
 - (id)initWithUnkeyedCoder:(NSCoder *)decoder
{
	int32_t sizeAsInt, displayModeAsInt;
	BOOL allowsCustomization, autosaves;

	NSString *codedID = [[decoder decodeObject] retain];

	if ([codedID isEqualToString:@""] || codedID == nil) {
		[codedID release];
		codedID = [[NSString alloc] initWithFormat:genericTitle, untitledToolbarCount++];
	}

	self = [super initWithIdentifier:codedID];
	if (self == nil) {
		[codedID release];
		return self;
	}
	
	identifier = codedID; // Retain already taken care of.

	dataSource = [[decoder decodeObject] retain];

	[decoder decodeValueOfObjCType:@encode(BOOL) at:&allowsCustomization];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&autosaves];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&paletteVisible];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&showsBaseline];
	
	if (!([decoder respondsToSelector:@selector(isAtEnd)] && [(NSUnarchiver *)decoder isAtEnd])) {
		if (sizeof(int) == sizeof(int32_t)) {
			[decoder decodeValueOfObjCType:@encode(int) at:&sizeAsInt];
			[decoder decodeValueOfObjCType:@encode(int) at:&displayModeAsInt];
			
		} else if (sizeof(short) == sizeof(int32_t)) {
			[decoder decodeValueOfObjCType:@encode(short) at:&sizeAsInt];
			[decoder decodeValueOfObjCType:@encode(short) at:&displayModeAsInt];
				
		} else {
			NSLog(NSLocalizedStringFromTableInBundle(@"Neither int nor short is 32 bits, so the size and display modes for GenericToolbar cannot be decoded.",
						@"GenericToolbar", [NSBundle bundleForClass:[GenericToolbar class]], @"Error message displayed when size and display modes cannot be unarchived"));
			sizeAsInt = (int32_t) TOOLBAR_SIZE_MODE_DEFAULT;
			displayModeAsInt = (int32_t) NSToolbarDisplayModeDefault;
		}
	} else {
		sizeAsInt = (int32_t) TOOLBAR_SIZE_MODE_DEFAULT;
		displayModeAsInt = (int32_t) NSToolbarDisplayModeDefault;
	}
	
	return [self finishCodedInitWithSizeMode:(NSToolbarSizeMode)sizeAsInt
								 displayMode:(NSToolbarDisplayMode)displayModeAsInt
						 allowsCustomization:allowsCustomization
								   autosaves:autosaves
							   showsBaseline:showsBaseline
									 visible:paletteVisible];
}

/*!
 * Assigns several values obtained from a coded archive to the toolbar. This method is called for both
 * keyed and unkeyed initialization, so it also provides a chance to do any setup before usage.
 */
- (id)finishCodedInitWithSizeMode:(NSToolbarSizeMode)sizeMode
					  displayMode:(NSToolbarDisplayMode)displayMode
			  allowsCustomization:(BOOL)allowsCustomization
						autosaves:(BOOL)autosaves
					showsBaseline:(BOOL)showsBaselineSeparator
						  visible:(BOOL)isVisible
{		
	[self setAllowsUserCustomization:allowsCustomization];
	[self setVisible:isVisible];
    // Be sure to call this after setting the visibility, becuase this will
    // cause the configuration to be saved.  If visibility is not yet set,
    // the incorrect visibility is saved.
	[self setAutosavesConfiguration:autosaves];
	
	[self setShowsBaselineSeparator:showsBaselineSeparator];
	
	if ([self respondsToSelector:@selector(setSizeMode:)])
		[self setSizeMode:sizeMode];
	[self setDisplayMode:displayMode];
	
    [super setDelegate:dataSource]; // Has to be super!
	
	return self;
}

#pragma mark -

- (void)encodeWithCoder:(NSCoder *)coder
{
//	[super encodeWithCoder:coder]; // NSToolbar has does not comply to NSCoding

	if ([coder respondsToSelector:@selector(allowsKeyedCoding)] && [coder allowsKeyedCoding]) {
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
	int32_t sizeAsInt = (int32_t) ([self respondsToSelector:@selector(sizeMode)]) ? [self sizeMode] : TOOLBAR_SIZE_MODE_DEFAULT;
	int32_t displayModeAsInt = (int32_t) [super displayMode];
	BOOL allowsCustomization = [super allowsUserCustomization];
	BOOL autosaves = [super autosavesConfiguration];

	[coder encodeObject:identifier forKey:@"identifier"];
		
	[coder encodeObject:dataSource forKey:@"dataSource"];
	
	[coder encodeBool:allowsCustomization forKey:@"allowsCustomization"];
	[coder encodeBool:autosaves forKey:@"autosaves"];
	[coder encodeBool:paletteVisible forKey:@"visible"];
	[coder encodeBool:showsBaseline forKey:@"showsBaselineSeparator"];

	[coder encodeInt:sizeAsInt forKey:@"sizeMode"];
	[coder encodeInt:displayModeAsInt forKey:@"displayMode"];
	
	[coder encodeBool:YES forKey:@"keyedCoding"]; // Keyed archive flag
}

/*!
 * Encodes the receiver into an unkeyed archive using coder. If there is no type
 * that is 32 bits wide, the size mode and display mode cannot be encoded. If
 * possible, use keyed archives to encode GenericToolbar; unkeyed archives just
 * aren't very safe.
 */
- (void)encodeWithUnkeyedCoder:(NSCoder *)coder
{
	int32_t sizeAsInt = (int32_t) ([self respondsToSelector:@selector(sizeMode)]) ? [self sizeMode] : TOOLBAR_SIZE_MODE_DEFAULT;
	int32_t displayModeAsInt = (int32_t) [super displayMode];
	BOOL allowsCustomization = [super allowsUserCustomization];
	BOOL autosaves = [super autosavesConfiguration];

	[coder encodeObject:identifier];
		
	[coder encodeObject:dataSource];
	
	[coder encodeValueOfObjCType:@encode(BOOL) at:&allowsCustomization];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&autosaves];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&paletteVisible];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&showsBaseline];

	if (sizeof(int) == sizeof(int32_t)) {
		[coder encodeValueOfObjCType:@encode(int) at:&sizeAsInt];
		[coder encodeValueOfObjCType:@encode(int) at:&displayModeAsInt];
		
	} else if (sizeof(short) == sizeof(int32_t)) {
		[coder encodeValueOfObjCType:@encode(short) at:&sizeAsInt];
		[coder encodeValueOfObjCType:@encode(short) at:&displayModeAsInt];	
		
	} else {
		NSLog(NSLocalizedStringFromTableInBundle(@"Neither int nor short is 32 bits, so the size and display modes for GenericToolbar cannot be encoded.",
					@"GenericToolbar", [NSBundle bundleForClass:[GenericToolbar class]], @"Error message displayed when size and display modes cannot be archived"));
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	GenericToolbar *copy = [[GenericToolbar allocWithZone:zone] initWithIdentifier:identifier dataSource:dataSource];
	[copy setDisplayMode:[self displayMode]];
	[copy setSizeMode:[self sizeMode]];
	[copy setVisible:[self isVisible]];
	
	[copy setAllowsUserCustomization:[self allowsUserCustomization]];
	[copy setAutosavesConfiguration:[self autosavesConfiguration]];
	
	if ([copy respondsToSelector:@selector(setSelectedItemIdentifier:)])
		[copy setSelectedItemIdentifier:[self selectedItemIdentifier]];
	
	copy->paletteVisible = self->paletteVisible;
	copy->showsBaseline = self->showsBaseline;
	
	[copy setShowsBaselineSeparator:[self showsBaselineSeparator]];
	
	return copy;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<GenericToolbar: %@>", identifier];
}

- (void)dealloc
{
	[identifier release];
	[self setDataSource:nil];
	
	[super dealloc];
}
#pragma mark -

/*!
 * Returns the toolbar's delegate. This is <em>not</em> the same as NSToolbar's
 * delegate in that it is shared by all GenericToolbars with the same data source.
 *
 * @see #setDelegate:
 * @see #dataSource
 * @see #setDataSource:
 * @functiongroup Setting the data source and delegate
 */
- (id)delegate
{
	return [dataSource delegate];
}

/*!
 * Sets the toolbar's delegate to <code>newDelegate</code>. This is significantly
 * different from NSToolbar's delegate in that it is shared by all instances of
 * GenericToolbars with the same data source. (This call is actually forwarded to
 * the data source object).
 *
 * @see #delegate
 * @see #dataSource
 * @see #setDataSource:
 */
- (void)setDelegate:(id)newDelegate
{
	[dataSource setDelegate:newDelegate];
}

/*!
 * Returns the toolbar's data source. This is very similar to NSToolbar's delegate.
 *
 * @see #setDataSource:
 * @see #delegate
 * @see #setDelegate:
 */
- (id)dataSource
{
	return dataSource;
}

/*!
 * Sets the toolbar's data source to <code>newDataSource</code>. The data source performs
 * the same function as NSToolbar's delegate, except that it is created and owned by
 * GenericToolbar. This allows the management of items to be transparent. You usually do
 * not need to call this method; toolbars created in InterfaceBuilder will have their
 * data sources encoded in the nib file automatically.
 *
 * @see #dataSource
 * @see #delegate
 * @see #setDelegate:
 */
- (void)setDataSource:(id)newDataSource
{
	if (dataSource != newDataSource) {
		[dataSource release];
		dataSource = [newDataSource retain];
		[super setDelegate:dataSource];
	}
}

- (BOOL)showsBaselineSeparator
{
	return showsBaseline;
}

- (void)setShowsBaselineSeparator:(BOOL)changedShowsBaseline
{
	if ([NSToolbar instancesRespondToSelector:@selector(setShowsBaselineSeparator:)])
		[super setShowsBaselineSeparator:changedShowsBaseline];
	showsBaseline = changedShowsBaseline;
}

- (BOOL)_isSelectableItemIdentifier:(NSString *)itemID
{
	id currentDataSource = [self dataSource];
	if (currentDataSource == nil)
		return NO;
	else
		return [[currentDataSource toolbarSelectableItemIdentifiers:self] containsObject:itemID];
}

@end
