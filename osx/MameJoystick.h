//
//  MameJoystick.h
//  mameosx
//
//  Created by Dave Dribin on 12/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MameInputDevice.h"

#define MameJoystickMaxAxes 8
#define MameJoystickMaxButtons 32
#define MameJoystickMaxPovs 4

@class DDHidJoystick;

@interface MameJoystick : MameInputDevice
{
    int mAxes[MameJoystickMaxAxes];
    int mButtons[MameJoystickMaxButtons];
    int mPovs[MameJoystickMaxPovs];
}

- (void) osd_init: (running_machine*) machine;

#pragma mark -
#pragma mark DDJoystickDelegate

- (void) ddhidJoystick: (DDHidJoystick *)  joystick
                 stick: (unsigned) stick
              xChanged: (int) value;

- (void) ddhidJoystick: (DDHidJoystick *)  joystick
                 stick: (unsigned) stick
              yChanged: (int) value;

- (void) ddhidJoystick: (DDHidJoystick *) joystick
            buttonDown: (unsigned) buttonNumber;

- (void) ddhidJoystick: (DDHidJoystick *) joystick
              buttonUp: (unsigned) buttonNumber;

@end
