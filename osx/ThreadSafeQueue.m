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

#import "ThreadSafeQueue.h"


@implementation ThreadSafeQueue

-(id)init {
    if (self = [super init]) {
        elements = [[NSMutableArray alloc] init];
        lock = [[NSConditionLock alloc] initWithCondition:0];
    }
    return self;
}

-(void)enqueue:(id)object {
    [lock lock];
    [elements addObject:object];
    [lock unlockWithCondition:1];
}

-(id)dequeue {
    [lock lockWhenCondition:1];
    id element = [[[elements objectAtIndex:0] retain] autorelease];
    [elements removeObjectAtIndex:0];
    int count = [elements count];
    [lock unlockWithCondition:(count > 0)?1:0];
    return element;
}

-(id)tryDequeue {
    id element = NULL;
    if ([lock tryLock]) {
        if ([lock condition] == 1) {
            element = [[[elements objectAtIndex:0] retain] autorelease];
            [elements removeObjectAtIndex:0];
        }
        int count = [elements count];
        [lock unlockWithCondition:(count > 0)?1:0];
    }
    return element;
}

-(void)dealloc {
    [elements release];
    [lock release];
    [super dealloc];
}

@end
