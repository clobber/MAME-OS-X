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
//  GenericToolbarItem.m
//  GenericToolbar
//

#import "GenericToolbarItem.h"

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4
	#define DEFAULT_TOOLBAR_ITEM_VISIBILITY_PRIORITY 0
#else
	#define DEFAULT_TOOLBAR_ITEM_VISIBILITY_PRIORITY NSToolbarItemVisibilityPriorityStandard
#endif

static unsigned int untitledItemCount = 0;
static NSString * const genericTitle = @"ComBelkadanGenerictoolbar_toolbarItemID_%u";

/*!
 * @class GenericToolbarItem
 * An NSCoding-compliant subclass of NSToolbarItem! GenericToolbarItem is easily modified in
 * InterfaceBuilder, supports target/action connections, and provides a useful interface for
 * using view items, items that can be enabled and disabled, and items with more than one
 * instance in a toolbar. <br/>
 * Also remember that the real name of this class is ComBelkadanGenerictoolbar_GenericToolbarItem.
 * This shouldn't matter, because of the #define in the header file. However, just don't get
 * confused in Interface Builder.
 *
 * @see GenericToolbar
 */
@implementation GenericToolbarItem

- (id)initWithItemIdentifier:(NSString *)givenID
{
	self = [super initWithItemIdentifier:givenID];
	if (self == nil) return self;
	
	identifier = [givenID retain];
	enabled = [self isEnabled];
	allowsDuplicates = [self allowsDuplicatesInToolbar];
	
	if ([self label] == nil) {
		[self setLabel:identifier];
	}
	if ([self paletteLabel] == nil) {
		[self setPaletteLabel:[self label]];
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
 * will be created for this toolbar item.
 *
 * @functiongroup Initializing with a coder
 */
- (id)initWithKeyedCoder:(NSCoder *)decoder
{
	int32_t tag, visibilityPriority;
	BOOL autovalidates;
	NSString *codedID, *imageName = @"";
	
	codedID = [[decoder decodeObjectForKey:@"identifier"] retain];
	
	if ([codedID isEqualToString:@""] || codedID == nil) {
		[codedID release];
		codedID = [[NSString alloc] initWithFormat:genericTitle, untitledItemCount++];
	}
	
	self = [super initWithItemIdentifier:codedID];
	if (self == nil) {
		[codedID release];
		return self;
	}
	
	identifier = codedID; // Retain taken care of
			
	[self setLabel:[decoder decodeObjectForKey:@"label"]];
	[self setPaletteLabel:[decoder decodeObjectForKey:@"paletteLabel"]];
	[self setToolTip:[decoder decodeObjectForKey:@"toolTip"]];

	imageName = [decoder decodeObjectForKey:@"image"];
	[self setMinSize:[decoder decodeSizeForKey:@"minSize"]];
	[self setMaxSize:[decoder decodeSizeForKey:@"maxSize"]];
	
	[self setAllowsDuplicatesInToolbar:[decoder decodeBoolForKey:@"allowsDuplicates"]];
	enabled = [decoder decodeBoolForKey:@"enabled"];
	autovalidates = [decoder decodeBoolForKey:@"autovalidates"];
	
	tag = (int32_t) [decoder decodeInt32ForKey:@"tag"];
	visibilityPriority = (int32_t) [decoder decodeInt32ForKey:@"visibilityPriority"];

	return [self finishCodedInitWithTag:tag imageName:imageName visibilityPriority:visibilityPriority autovalidates:autovalidates];
}

/*!
 * Initializes a newly allocated instance from data in the unkeyed decoder.
 * If the encoded data does not contain an identifier string, a default one
 * will be created for this toolbar item. Also, if there is no type that is 32 bits
 * wide, the tag and visibility priority cannot be decoded, in which case the
 * default values will be substituted. If possible, use keyed archives to encode
 * GenericToolbarItem; unkeyed archives just aren't very safe.
 */
- (id)initWithUnkeyedCoder:(NSCoder *)decoder
{
	int32_t tag, visibilityPriority;
	BOOL autovalidates;
	NSString *codedID, *imageName = @"";
	
	codedID = [[decoder decodeObject] retain];

	if ([codedID isEqualToString:@""] || codedID == nil) {
		[codedID release];
	codedID = [[NSString alloc] initWithFormat:genericTitle, untitledItemCount++];
	}

	self = [super initWithItemIdentifier:codedID];
	if (self == nil) {
		[codedID release];
		return self;
	}
			
	identifier = codedID;
			
	[self setLabel:[decoder decodeObject]];
	[self setPaletteLabel:[decoder decodeObject]];
	[self setToolTip:[decoder decodeObject]];

	imageName = [decoder decodeObject];
	[self setMinSize:[decoder decodeSize]];
	[self setMaxSize:[decoder decodeSize]];
	
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&allowsDuplicates];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&enabled];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&autovalidates];
	
	if (!([decoder respondsToSelector:@selector(isAtEnd)] && [(NSUnarchiver *)decoder isAtEnd])) {
		if (sizeof(int) == sizeof(int32_t)) {
			[decoder decodeValueOfObjCType:@encode(int) at:&tag];
			[decoder decodeValueOfObjCType:@encode(int) at:&visibilityPriority];
			
		} else if (sizeof(short) == sizeof(int32_t)) {
			[decoder decodeValueOfObjCType:@encode(short) at:&tag];
			[decoder decodeValueOfObjCType:@encode(short) at:&visibilityPriority];
				
		} else {
			NSLog(NSLocalizedStringFromTableInBundle(@"Neither int nor short is 32 bits, so the tag value and visibility priority of GenericToolbarItem cannot be decoded.",
					@"GenericToolbar", [NSBundle bundleForClass:[GenericToolbarItem class]], @"Error message displayed when the tag value and visibility priority cannot be unarchived"));
			tag = 0;
			visibilityPriority = DEFAULT_TOOLBAR_ITEM_VISIBILITY_PRIORITY;
		}
	} else {
		tag = 0;
		visibilityPriority = DEFAULT_TOOLBAR_ITEM_VISIBILITY_PRIORITY;
	}

	return [self finishCodedInitWithTag:tag imageName:imageName visibilityPriority:visibilityPriority autovalidates:autovalidates];
}

/*!
 * Assigns several values obtained from a coded archive to the toolbar item. This method
 * is called for both keyed and unkeyed initialization, so it also provides a chance to
 * do any setup before usage.
 */
- (id)finishCodedInitWithTag:(int)tag imageName:(NSString *)imageName visibilityPriority:(int)visibilityPriority autovalidates:(BOOL)autovalidates
{
	[self setTag:tag];
	if (imageName != nil) {
		NSImage *icon = [NSImage imageNamed:imageName];
		if (icon == nil) {
			icon = [[NSImage alloc] initWithSize:NSZeroSize];
			[icon setName:imageName];
		}
		[self setImage:icon];
	}
	[super setEnabled:enabled]; // Not guaranteed to work...unfortunately.
	
	if ([self respondsToSelector:@selector(setVisibilityPriority:)])
		[self setVisibilityPriority:visibilityPriority];

	if ([self respondsToSelector:@selector(setAutovalidates:)])
		[self setAutovalidates:autovalidates];
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<GenericToolbarItem: %@>", [self itemIdentifier]];
}

#pragma mark -

- (void)encodeWithCoder:(NSCoder *)coder
{	
//    [super encodeWithCoder:coder]; // NSToolbarItem does not comply to NSCoding

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
	int32_t tag = (int32_t) [self tag];
	int32_t visibilityPriority = (int32_t) ([self respondsToSelector:@selector(visibilityPriority)]) ? [self visibilityPriority] : DEFAULT_TOOLBAR_ITEM_VISIBILITY_PRIORITY;
	BOOL autovalidates = ([self respondsToSelector:@selector(autovalidates)]) ? [self autovalidates] : YES;

	[coder encodeObject:identifier forKey:@"identifier"];
	
	[coder encodeObject:[self label] forKey:@"label"];
	[coder encodeObject:[self paletteLabel] forKey:@"paletteLabel"];
	[coder encodeObject:[self toolTip] forKey:@"toolTip"];
	
	[coder encodeObject:[[self image] name] forKey:@"image"];
	[coder encodeSize:[self minSize] forKey:@"minSize"];
	[coder encodeSize:[self maxSize] forKey:@"maxSize"];
	
	[coder encodeBool:allowsDuplicates forKey:@"allowsDuplicates"];
	[coder encodeBool:enabled forKey:@"enabled"];
	[coder encodeBool:autovalidates forKey:@"autovalidates"];

	[coder encodeInt32:tag forKey:@"tag"];
	[coder encodeInt32:visibilityPriority forKey:@"visibilityPriority"];
	
	[coder encodeBool:YES forKey:@"keyedCoding"]; // Flag
}

/*!
 * Encodes the receiver into an unkeyed archive using coder. If there is no type
 * that is 32 bits wide, the tag and visibility priority cannot be encoded. If
 * possible, use keyed archives to encode GenericToolbarItem; unkeyed archives just
 * aren't very safe.
 */
- (void)encodeWithUnkeyedCoder:(NSCoder *)coder
{
	int32_t tag = (int32_t) [self tag];
	int32_t visibilityPriority = (int32_t) ([self respondsToSelector:@selector(visibilityPriority)]) ? [self visibilityPriority] : DEFAULT_TOOLBAR_ITEM_VISIBILITY_PRIORITY;
	BOOL autovalidates = ([self respondsToSelector:@selector(autovalidates)]) ? [self autovalidates] : YES;

	[coder encodeObject:identifier];
	
	[coder encodeObject:[self label]];
	[coder encodeObject:[self paletteLabel]];
	[coder encodeObject:[self toolTip]];
	
	[coder encodeObject:[[self image] name]];
	[coder encodeSize:[self minSize]];
	[coder encodeSize:[self maxSize]];
	
	[coder encodeValueOfObjCType:@encode(BOOL) at:&allowsDuplicates];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&enabled];
	[coder encodeValueOfObjCType:@encode(BOOL) at:&autovalidates];

	if (sizeof(int) == sizeof(int32_t)) {
		[coder encodeValueOfObjCType:@encode(int) at:&tag];
		[coder encodeValueOfObjCType:@encode(int) at:&visibilityPriority];
		
	} else if (sizeof(short) == sizeof(int32_t)) {
		[coder encodeValueOfObjCType:@encode(short) at:&tag];
		[coder encodeValueOfObjCType:@encode(short) at:&visibilityPriority];
		
	} else {
		NSLog(NSLocalizedStringFromTableInBundle(@"Neither int nor short is 32 bits, so the tag value and visibility priority of GenericToolbarItem cannot be encoded.",
				@"GenericToolbar", [NSBundle bundleForClass:[GenericToolbarItem class]], @"Error message displayed when the tag value and visibility priority cannot be archived"));
	}
}

- (void)dealloc
{
#if 1
    NSArray * bindings = [self exposedBindings];
    NSString * binding;
    NSEnumerator * e = [bindings objectEnumerator];
    while (binding = [e nextObject])
    {
        [self unbind: binding];
    }
#endif
    
	[identifier release];
	[super dealloc];
}

#pragma mark -

- (BOOL)allowsDuplicatesInToolbar
{
	return allowsDuplicates;
}

/*!
 * Set whether or not this item can show up more than once in a toolbar. Changing
 * this while the item is being used (in any way) is not recommended.
 *
 * @functiongroup Setting toolbar item attributes
 */
- (void)setAllowsDuplicatesInToolbar:(BOOL)changedAllowsDuplicates
{
	allowsDuplicates = changedAllowsDuplicates;
}

- (BOOL)isEnabled
{
	return enabled && [super isEnabled];
}

- (void)setEnabled:(BOOL)newEnabled
{
	[super setEnabled:newEnabled];
	enabled = newEnabled;
} 

- (void)setView:(NSView *)newView
{
	[super setView:newView];
	
	if (newView != nil) {
		NSSize viewSize = [newView frame].size;
		
		NSSize itemSize = [self minSize];
		if (itemSize.width < 0)
			itemSize.width = viewSize.width;
		if (itemSize.height < 0)
			itemSize.height = viewSize.height;
		[self setMinSize:itemSize];
		
		itemSize = [self maxSize];
		if (itemSize.width < 0)
			itemSize.width = viewSize.width;
		if (itemSize.height < 0)
			itemSize.height = viewSize.height;
		[self setMaxSize:itemSize];
	}
}

#pragma mark -

/*!
 * If this is not a view item, creates an NSToolbarItem with the same attributes as
 * the receiver. This method was a workaround for a problem that has since been fixed.
 *
 * @see #shouldCreateNSToolbarItem
 * @deprecated in version 1.0
 * @functiongroup Deprecated methods
 */
- (NSToolbarItem *)asNSToolbarItem
{
	NSToolbarItem *copy;
	if (![self shouldCreateNSToolbarItem]) {
		copy = [self copy];
	
	} else {
/*		if (allowsDuplicates) {
			copy = [[DuplicatableNSToolbarItem alloc]	initWithItemIdentifier:identifier];
			
		} else { */
			copy = [[NSToolbarItem alloc]				initWithItemIdentifier:identifier];
//		}
			
		[copy setImage:	[self image]];
		[copy setLabel:	[self label]];
		[copy setTag:	[self tag]];
		[copy setEnabled:enabled];
		
		[copy setAction:		[self action]];
		[copy setTarget:		[self target]];
		[copy setToolTip:		[self toolTip]];
		[copy setPaletteLabel:	[self paletteLabel]];
		
		[copy setView:	[self view]];
		
		[copy setMinSize:		[self minSize]];
		[copy setMaxSize:		[self maxSize]];
		
		[copy setMenuFormRepresentation:[self menuFormRepresentation]];
		
		if ([copy respondsToSelector:@selector(setAutovalidates:)])
			[copy setAutovalidates:[self autovalidates]];

		if ([copy respondsToSelector:@selector(setVisibilityPriority:)])
			[copy setVisibilityPriority:[self visibilityPriority]];
	}
	
	return [copy autorelease];
}

/*!
 * Returns <code>YES</code> if the <code>asToolbarItem</code> method should return
 * an NSToolbarItem, <code>NO</code> if it should just copy the <code>GenericToolbarItem</code>.
 * This method was a workaround for a problem that has since been fixed.
 *
 * @see #asNSToolbarItem
 * @deprecated in version 1.0
 */
- (BOOL)shouldCreateNSToolbarItem
{
	return ([self view] == nil);
//	return YES;
}

- (id)copyWithZone:(NSZone *)zone
{
	GenericToolbarItem *copy = [super copyWithZone:zone];
	
	copy->identifier = [[copy itemIdentifier] retain];
	copy->allowsDuplicates = self->allowsDuplicates;
	copy->enabled = self->enabled;
	
	return copy;
}

@end

/*
#pragma mark -
@implementation DuplicatableNSToolbarItem
- (BOOL)allowsDuplicatesInToolbar
{
	return YES;
}

@end
*/