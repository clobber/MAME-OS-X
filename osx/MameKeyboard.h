//
//  MameKeyboard.h
//  mameosx
//
//  Created by Dave Dribin on 10/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MameInputDevice.h"

#define MameKeyboardMaxKeys 256

@class DDHidKeyboard;


@interface MameKeyboard : MameInputDevice
{
    uint32_t mKeyStates[MameKeyboardMaxKeys];
}

- (void) osd_init: (running_machine*) machine;

@end
