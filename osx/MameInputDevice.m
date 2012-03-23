//
//  MameInputDevice.m
//  mameosx
//
//  Created by Dave Dribin on 10/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MameInputDevice.h"

@implementation MameInputDevice

- (id) initWithDevice: (DDHidDevice *) device mameTag: (int) mameTag
              enabled: (BOOL *) enabled;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mDevice = [device retain];
    mMameTag = mameTag;
    mEnabled = enabled;
    
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mDevice release];
    
    mDevice = nil;
    [super dealloc];
}

- (void) osd_init;
{
}

- (void) gameFinished;
{
    [mDevice stopListening];
}

- (BOOL) tryStartListening;
{
    BOOL success = NO;
    @try
    {
        [mDevice startListening];
        success = YES;
    }
    @catch (id e)
    {
        JRLogInfo(@"tryStartListening exception: %@", e);
        success = NO;
    }
    return success;
}

- (void) stopListening;
{
    [mDevice stopListening];
}

- (NSString *) format: (NSString *) format, ...;
{
    va_list arguments;
    va_start(arguments, format);
    NSString * string = [[NSString alloc] initWithFormat: format
                                               arguments: arguments];
    [string autorelease];
    va_end(arguments);
    return string;
}

- (INT32) normalizeRawValue: (INT32) rawValue
                     rawMin: (INT32) rawMin
                     rawMax: (INT32) rawMax;
{
	INT32 center = (rawMax + rawMin) / 2;
    
	// make sure we have valid data
	if (rawMin >= rawMax)
		return rawValue;
	
	// above center
	if (rawValue >= center)
	{
		INT32 result = ((INT64)(rawValue - center) *
                        (INT64)INPUT_ABSOLUTE_MAX / (INT64)(rawMax - center));
		return MIN(result, INPUT_ABSOLUTE_MAX);
	}
	
	// below center
	else
	{
		INT32 result = -((INT64)(center - rawValue) *
                         (INT64)-INPUT_ABSOLUTE_MIN / (INT64)(center - rawMin));
		return MAX(result, INPUT_ABSOLUTE_MIN);
	}
}

@end
