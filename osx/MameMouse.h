//
//  MameMouse.h
//  mameosx
//
//  Created by Dave Dribin on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MameInputDevice.h"

#define MameMouseMaxButtons 32

@class DDHidMouse;

@interface MameMouse : MameInputDevice
{
    int mX;
    int mY;
    int mButtons[MameMouseMaxButtons];
}

- (void) osd_init: (running_machine*) machine;

#pragma mark -
#pragma mark DDHidMouseDelegate

- (void) ddhidMouse: (DDHidMouse *) mouse xChanged: (SInt32) deltaX;
- (void) ddhidMouse: (DDHidMouse *) mouse yChanged: (SInt32) deltaY;
- (void) ddhidMouse: (DDHidMouse *) mouse buttonDown: (unsigned) buttonNumber;
- (void) ddhidMouse: (DDHidMouse *) mouse buttonUp: (unsigned) buttonNumber;

@end
