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
//#include "driver.h"
#include "emu.h"

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
	//const game_driver * driver = drivers[game];
    const game_driver * driver = &driver_list::driver(game);
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

    //const game_driver *clone_of = driver_get_clone(gamedrv);
    int clone_of = driver_list::clone(*gamedrv);
    
    mGameName = [[NSString alloc] initWithUTF8String: gamedrv->name];
    //if (clone_of != NULL)
    if (clone_of != -1)
        //mCloneName = [[NSString alloc] initWithUTF8String: clone_of->name];
        mCloneName = [[NSString alloc] initWithUTF8String: driver_list::driver(clone_of).name];
    else
        mCloneName = @"";
    mDescription = [[NSString alloc] initWithUTF8String: gamedrv->description];
    
	/* no count or records means not found */
	//if (count == 0 || records == NULL)
    //driver_enumerator * drvlist;
    simple_list<audit_record>	m_record_list;
    if (m_record_list.count() == 0)
    {
        mStatus = media_auditor::NOTFOUND;
		return self;
    }

	int overall_status = media_auditor::CORRECT;
    //media_auditor::summary overall_status = CORRECT;
	int notfound = 0;
	int recnum;
    BOOL output = YES;
    astring *string;
    
    NSMutableString * notes = [NSMutableString string];
    
	/* loop over records */
	//for (recnum = 0; recnum < count; recnum++)
    for (audit_record *record = m_record_list.first(); record != NULL; record = record->next())
	{
		//const audit_record *record = &records[recnum];
		int best_new_status = media_auditor::INCORRECT;
        
		/* skip anything that's fine */
		if (record->substatus() == audit_record::SUBSTATUS_GOOD)
			continue;
        
		/* count the number of missing items */
		if (record->status() == audit_record::STATUS_NOT_FOUND)
			notfound++;
        
		/* output the game name, file name, and length (if applicable) */
		if (string != NULL)
		{
			[notes appendFormat: @"%s", record->name()];
			if (record->expected_length() > 0)
				[notes appendFormat: @" (%d bytes)", record->expected_length()];
			[notes appendFormat: @" - "];
		}
        
		/* use the substatus for finer details */
		switch (record->substatus())
		{
			case audit_record::SUBSTATUS_GOOD_NEEDS_REDUMP:
				if (string != NULL) [notes appendString: @"NEEDS REDUMP\n"];
				best_new_status = media_auditor::BEST_AVAILABLE;
				break;
                
			case audit_record::SUBSTATUS_FOUND_NODUMP:
				if (string != NULL) [notes appendString: @"NO GOOD DUMP KNOWN\n"];
				best_new_status = media_auditor::BEST_AVAILABLE;
				break;
                
			case audit_record::SUBSTATUS_FOUND_BAD_CHECKSUM:
				if (string != NULL)
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
                
			case audit_record::SUBSTATUS_FOUND_WRONG_LENGTH:
				if (string != NULL) [notes appendFormat: @"INCORRECT LENGTH: %d bytes\n", record->actual_length()];
				break;
                
			case audit_record::SUBSTATUS_NOT_FOUND:
				if (string != NULL) [notes appendFormat: @"NOT FOUND\n"];
				break;
                
			case audit_record::SUBSTATUS_NOT_FOUND_NODUMP:
				if (string != NULL) [notes appendFormat: @"NOT FOUND - NO GOOD DUMP KNOWN\n"];
				best_new_status = media_auditor::BEST_AVAILABLE;
				break;
                
			case audit_record::SUBSTATUS_NOT_FOUND_OPTIONAL:
				if (string != NULL) [notes appendFormat: @"NOT FOUND BUT OPTIONAL\n"];
				best_new_status = media_auditor::BEST_AVAILABLE;
				break;
                
			case audit_record::SUBSTATUS_NOT_FOUND_PARENT:
				if (string != NULL) [notes appendFormat: @"NOT FOUND (shared with parent)\n"];
				break;
                
			case audit_record::SUBSTATUS_NOT_FOUND_BIOS:
				if (string != NULL) [notes appendFormat: @"NOT FOUND (BIOS)\n"];
				break;
		}
        
		/* downgrade the overall status if necessary */
		overall_status = MAX(overall_status, best_new_status);
	}
    
	mStatus = (notfound == count) ? media_auditor::NOTFOUND : overall_status;
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
        case media_auditor::INCORRECT:
            return @"Bad";
            
        case media_auditor::CORRECT:
            return @"Good";
            
        case media_auditor::BEST_AVAILABLE:
            return @"Best Available";
            
        case media_auditor::NOTFOUND:
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
