//
//  MameInputDevice.h
//  mameosx
//
//  Created by Dave Dribin on 10/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// MAME headers
#include "driver.h"

@class DDHidDevice;

@interface MameInputDevice : NSObject
{
    @protected
    DDHidDevice * mDevice;
    int mMameTag;

    /* 
     * Pointer into MameInputController's enabled flag.  This allows us
     * to check the enabled state without sending a message.  This is important
     * in the input callbacks because they get called every frame and for
     * each input element.  This does add a reverse dependency to the input
     * controller, but it's too much pain to keep our own enabled flag with
     * threading issues and such.
     */
    BOOL * mEnabled;
}

- (id) initWithDevice: (DDHidDevice *) device mameTag: (int) mameTag
              enabled: (BOOL *) enabled;

- (void) osd_init;

- (void) gameFinished;

- (BOOL) tryStartListening;

- (void) stopListening;

- (NSString *) format: (NSString *) format, ...;

- (INT32) normalizeRawValue: (INT32) rawValue
                     rawMin: (INT32) rawMin
                     rawMax: (INT32) rawMax;

@end
