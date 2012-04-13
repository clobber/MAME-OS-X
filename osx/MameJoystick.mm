//
//  MameJoystick.m
//  mameosx
//
//  Created by Dave Dribin on 12/8/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MameJoystick.h"
#import "DDHidLib.h"

// MAME headers
//#include "driver.h"
#include "emu.h"
#include "input.h"

enum
{
    POVDIR_LEFT = 0,
    POVDIR_RIGHT,
    POVDIR_UP,
    POVDIR_DOWN
};

@implementation MameJoystick


static INT32 joystickAxisGetState(void *device_internal, void *item_internal)
{
    MameJoystick * joystick = (MameJoystick *) device_internal;
    if (!(*joystick->mEnabled))
        return 0;

    int * axisState = (INT32 *) item_internal;
    return (*axisState);
}

static INT32 joystickPovGetState(void *device_internal, void *item_internal)
{
    MameJoystick * joystick = (MameJoystick *) device_internal;
    if (!(*joystick->mEnabled))
        return 0;

    int povnum = (FPTR)item_internal / 4;
    int povdir = (FPTR)item_internal % 4;
    
    int value = joystick->mPovs[povnum];
    switch (povdir)
    {
        // anywhere from 0-45 (315) deg to 0+45 (45) deg
        case POVDIR_UP:
            return (value != -1 && (value >= 31500 || value <= 4500));
            
            // anywhere from 90-45 (45) deg to 90+45 (135) deg
        case POVDIR_RIGHT:
            return (value != -1 && (value >= 4500 && value <= 13500));
            
            // anywhere from 180-45 (135) deg to 180+45 (225) deg
        case POVDIR_DOWN:
            return (value != -1 && (value >= 13500 && value <= 22500));
            
            // anywhere from 270-45 (225) deg to 270+45 (315) deg
        case POVDIR_LEFT:
            return (value != -1 && (value >= 22500 && value <= 31500));
    }
    return 0;
}

static INT32 joystickButtonGetState(void *device_internal, void *item_internal)
{
    MameJoystick * joystick = (MameJoystick *) device_internal;
    if (!(*joystick->mEnabled))
        return 0;

    int * buttonState = (INT32 *) item_internal;
    return (*buttonState);
}

- (void) osd_init: (running_machine*) machine;
{
    DDHidJoystick * joystick = (DDHidJoystick *) mDevice;
    [joystick setDelegate: self];
    
    NSString * name = [NSString stringWithFormat: @"Joystick %d", mMameTag];
    JRLogInfo(@"Adding joystick device: %@", name);
    input_device * device = input_device_add(*machine, DEVICE_CLASS_JOYSTICK,
                                             [name UTF8String],
                                             (void *) self);
    
    unsigned i;
    // TODO: Handle more sticks.
    // for (i = 0; i < [joystick countOfSticks]; i++)
    i = 0;
    {
        DDHidJoystickStick * stick = [joystick objectInSticksAtIndex: i];
        NSString * name;
        int * axisState;
        
        name = @"X-Axis";
        axisState = &mAxes[0];
        input_device_item_add(device,
                              [name UTF8String],
                              axisState,
                              ITEM_ID_XAXIS,
                              joystickAxisGetState);
        
        name = @"Y-Axis";
        axisState = &mAxes[1];
        input_device_item_add(device,
                              [name UTF8String],
                              axisState,
                              ITEM_ID_YAXIS,
                              joystickAxisGetState);
        
        int j;
        for (j = 0; j < [stick countOfStickElements]; j++)
        {
            int axisNumber = j+2;
            name = [self format: @"Axis %d", axisNumber+1];
            axisState = &mAxes[axisNumber];
            input_device_item_add(device,
                                  [name UTF8String],
                                  axisState,
                                  (input_item_id)(ITEM_ID_XAXIS + axisNumber),
                                  joystickAxisGetState);
        }
        
        for (j = 0; j < [stick countOfPovElements]; j++)
        {
            DDHidElement * pov = [stick objectInPovElementsAtIndex: j];
            name = [self format: @"Hat Switch %d U", j+1];
            input_device_item_add(device,
                                  [name UTF8String],
                                  (void *) (j * 4 + POVDIR_UP),
                                  ITEM_ID_OTHER_SWITCH,
                                  joystickPovGetState);
            
            name = [self format: @"Hat Switch %d D", j+1];
            input_device_item_add(device,
                                  [name UTF8String],
                                  (void *) (j * 4 + POVDIR_DOWN),
                                  ITEM_ID_OTHER_SWITCH,
                                  joystickPovGetState);
            
            name = [self format: @"Hat Switch %d L", j+1];
            input_device_item_add(device,
                                  [name UTF8String],
                                  (void *) (j * 4 + POVDIR_LEFT),
                                  ITEM_ID_OTHER_SWITCH,
                                  joystickPovGetState);
            
            name = [self format: @"Hat Switch %d R", j+1];
            input_device_item_add(device,
                                  [name UTF8String],
                                  (void *) (j * 4 + POVDIR_RIGHT),
                                  ITEM_ID_OTHER_SWITCH,
                                  joystickPovGetState);
        }
    }
    
    NSArray * buttons = [joystick buttonElements];
    int buttonCount = MIN([buttons count], MameJoystickMaxButtons);
    for (i = 0; i < buttonCount; i++)
    {
        DDHidElement * button = [buttons objectAtIndex: i];
        
        NSString * name = [self format: @"Button %d", i+1];
        int * buttonState = &mButtons[i];
        input_device_item_add(device,
                              [name UTF8String],
                              buttonState,
                              (input_item_id)(ITEM_ID_BUTTON1 + i),
                              joystickButtonGetState);
    }
}

#pragma mark -
#pragma mark DDJoystickDelegate

- (void) ddhidJoystick: (DDHidJoystick *)  joystick
                 stick: (unsigned) stick
              xChanged: (int) value;
{
    value = [self normalizeRawValue: value
                             rawMin: DDHID_JOYSTICK_VALUE_MIN
                             rawMax: DDHID_JOYSTICK_VALUE_MAX];
    mAxes[0] = value;
}

- (void) ddhidJoystick: (DDHidJoystick *)  joystick
                 stick: (unsigned) stick
              yChanged: (int) value;

{
    value = [self normalizeRawValue: value
                             rawMin: DDHID_JOYSTICK_VALUE_MIN
                             rawMax: DDHID_JOYSTICK_VALUE_MAX];
    mAxes[1] = value;
}

- (void) ddhidJoystick: (DDHidJoystick *) joystick
                 stick: (unsigned) stick
             otherAxis: (unsigned) otherAxis
          valueChanged: (int) value;
{
    value = [self normalizeRawValue: value
                             rawMin: DDHID_JOYSTICK_VALUE_MIN
                             rawMax: DDHID_JOYSTICK_VALUE_MAX];
    int axisNumber = otherAxis+2;
    mAxes[axisNumber] = value;
}


- (void) ddhidJoystick: (DDHidJoystick *) joystick
                 stick: (unsigned) stick
             povNumber: (unsigned) povNumber
          valueChanged: (int) value;
{
    mPovs[povNumber] = value;
}

- (void) ddhidJoystick: (DDHidJoystick *) joystick
            buttonDown: (unsigned) buttonNumber;
{
    mButtons[buttonNumber] = 1;
}

- (void) ddhidJoystick: (DDHidJoystick *) joystick
              buttonUp: (unsigned) buttonNumber;
{
    mButtons[buttonNumber] = 0;
}

@end
