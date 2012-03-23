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

#import "RomAuditSummary.h"
#include "driver.h"

@implementation RomAuditSummary

- (id) init;
{
    NSLog(@"init");
    return [self initWithGameIndex: 0 recordCount: 0 records: NULL];
}

- (id) initWithGameIndex: (int) game
             recordCount: (int) count
                 records: (const audit_record *) records;
{
	const game_driver * driver = drivers[game];
    return [self initWithGameDriver: driver
                        recordCount: count
                            records: records];
}

- (id) initWithGameDriver: (const game_driver *) gamedrv
              recordCount: (int) count
                  records: (const audit_record *) records;
{
    self = [super init];
    if (self == nil)
        return nil;

    const game_driver *clone_of = driver_get_clone(gamedrv);
    
    mGameName = [[NSString alloc] initWithUTF8String: gamedrv->name];
    if (clone_of != NULL)
        mCloneName = [[NSString alloc] initWithUTF8String: clone_of->name];
    else
        mCloneName = @"";
    mDescription = [[NSString alloc] initWithUTF8String: gamedrv->description];
    
	/* no count or records means not found */
	if (count == 0 || records == NULL)
    {
        mStatus = NOTFOUND;
		return self;
    }

	int overall_status = CORRECT;
	int notfound = 0;
	int recnum;
    BOOL output = YES;
    
    NSMutableString * notes = [NSMutableString string];
    
	/* loop over records */
	for (recnum = 0; recnum < count; recnum++)
	{
		const audit_record *record = &records[recnum];
		int best_new_status = INCORRECT;
        
		/* skip anything that's fine */
		if (record->substatus == SUBSTATUS_GOOD)
			continue;
        
		/* count the number of missing items */
		if (record->status == AUDIT_STATUS_NOT_FOUND)
			notfound++;
        
		/* output the game name, file name, and length (if applicable) */
		if (output)
		{
			[notes appendFormat: @"%s", record->name];
			if (record->explength > 0)
				[notes appendFormat: @" (%d bytes)", record->explength];
			[notes appendFormat: @" - "];
		}
        
		/* use the substatus for finer details */
		switch (record->substatus)
		{
			case SUBSTATUS_GOOD_NEEDS_REDUMP:
				if (output) [notes appendString: @"NEEDS REDUMP\n"];
				best_new_status = BEST_AVAILABLE;
				break;
                
			case SUBSTATUS_FOUND_NODUMP:
				if (output) [notes appendString: @"NO GOOD DUMP KNOWN\n"];
				best_new_status = BEST_AVAILABLE;
				break;
                
			case SUBSTATUS_FOUND_BAD_CHECKSUM:
				if (output)
				{
#if 0
					char hashbuf[512];
                    
					mame_printf_info("INCORRECT CHECKSUM:\n");
					hash_data_print(record->exphash, 0, hashbuf);
					mame_printf_info("EXPECTED: %s\n", hashbuf);
					hash_data_print(record->hash, 0, hashbuf);
					mame_printf_info("   FOUND: %s\n", hashbuf);
#endif
				}
				break;
                
			case SUBSTATUS_FOUND_WRONG_LENGTH:
				if (output) [notes appendFormat: @"INCORRECT LENGTH: %d bytes\n", record->length];
				break;
                
			case SUBSTATUS_NOT_FOUND:
				if (output) [notes appendFormat: @"NOT FOUND\n"];
				break;
                
			case SUBSTATUS_NOT_FOUND_NODUMP:
				if (output) [notes appendFormat: @"NOT FOUND - NO GOOD DUMP KNOWN\n"];
				best_new_status = BEST_AVAILABLE;
				break;
                
			case SUBSTATUS_NOT_FOUND_OPTIONAL:
				if (output) [notes appendFormat: @"NOT FOUND BUT OPTIONAL\n"];
				best_new_status = BEST_AVAILABLE;
				break;
                
			case SUBSTATUS_NOT_FOUND_PARENT:
				if (output) [notes appendFormat: @"NOT FOUND (shared with parent)\n"];
				break;
                
			case SUBSTATUS_NOT_FOUND_BIOS:
				if (output) [notes appendFormat: @"NOT FOUND (BIOS)\n"];
				break;
		}
        
		/* downgrade the overall status if necessary */
		overall_status = MAX(overall_status, best_new_status);
	}
    
	mStatus = (notfound == count) ? NOTFOUND : overall_status;
    mNotes = [notes copy];

    return self;
}

- (void) dealloc
{
    [mGameName release];
    [mCloneName release];
    [mDescription release];
    [mNotes release];
    [super dealloc];
}

- (NSString *) gameName;
{
    return mGameName;
}

- (NSString *) cloneName;
{
    return mCloneName;
}

- (NSString *) description;
{
    return mDescription;
}

- (int) status;
{
    return mStatus;
}

- (NSString *) statusString;
{
    switch (mStatus)
    {
        case INCORRECT:
            return @"Bad";
            
        case CORRECT:
            return @"Good";
            
        case BEST_AVAILABLE:
            return @"Best Available";
            
        case NOTFOUND:
            return @"Not Found";
            
        default:
            return @"N/A";
    }
}

- (NSString *) notes;
{
    return mNotes;
}

static NSString *keysToEncode[] = {@"mGameName", @"mCloneName", @"mDescription", @"mStatus", @"mNotes", nil};

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
    int i;
    BOOL useKeyBasedArchival = [aCoder allowsKeyedCoding];
    for(i=0; keysToEncode[i]; i++) {
        NSString *key = keysToEncode[i];
        id value = [self valueForKey: key];
        if (useKeyBasedArchival)
            [aCoder encodeObject: value forKey: key];
        else
            [aCoder encodeObject: value];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    int i;
    BOOL useKeyBasedArchival = [aDecoder allowsKeyedCoding];
    for(i=0; keysToEncode[i]; i++) {
        NSString *key = keysToEncode[i];
        id value;
        if (useKeyBasedArchival)
            value = [aDecoder decodeObjectForKey: key];
        else
            value = [aDecoder decodeObject];
        [self setValue: value forKey: key];
    }
    
    return self;
}
@end
