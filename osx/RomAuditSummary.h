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

#import <Cocoa/Cocoa.h>
//#include "driver.h"
#include "emu.h"
#import "audit.h"


@interface RomAuditSummary : NSObject <NSCoding> {
    NSString * mGameName;
    NSString * mCloneName;
    NSString * mDescription;
    int mStatus;
    NSString * mNotes;
}

// int audit_summary(int game, int count, const audit_record *records, int output)

- (id) initWithGameIndex: (int) game
             recordCount: (int) count
                 records: (const audit_record *) records;

- (id) initWithGameDriver: (const game_driver *) driver
              recordCount: (int) count
                  records: (const audit_record *) records;

- (NSString *) gameName;

- (NSString *) cloneName;

- (NSString *) description;

- (int) status;

- (NSString *) statusString;

- (NSString *) notes;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
@end
