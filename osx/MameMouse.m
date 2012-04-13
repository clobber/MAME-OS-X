//
//  MameMouse.m
//  mameosx
//
//  Created by Dave Dribin on 10/29/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MameMouse.h"
#import "DDHidLib.h"

// MAME headers
//#include "driver.h"
#include "emu.h"

@implementation MameMouse

static INT32 mouseAxisGetState(void *device_internal, void *item_internal)
{
    MameMouse * mouse = (MameMouse *) device_internal;
    if (!(*mouse->mEnabled))
        return 0;
    
    INT32 * axisState = (INT32 *) item_internal;
    INT32 result = (*axisState) * INPUT_RELATIVE_PER_PIXEL;
    *axisState = 0;
    return result;
}

static INT32 mouseButtonGetState(void *device_internal, void *item_internal)
{
    MameMouse * mouse = (MameMouse *) device_internal;
    if (!(*mouse->mEnabled))
        return 0;

    int * buttonState = (INT32 *) item_internal;
    return (*buttonState);
}

- (void) osd_init: (running_machine*) machine;
{
    DDHidMouse * mouse = (DDHidMouse *) mDevice;;
    [mouse setDelegate: self];
    
    NSString * name = [NSString stringWithFormat: @"Mouse %d", mMameTag];
    JRLogInfo(@"Adding mouse device: %@", name);
    input_device * device = input_device_add(*machine, DEVICE_CLASS_MOUSE,
                                             [name UTF8String],
                                             (void *) self);
    
    DDHidElement * axis;
    
    axis = [mouse xElement];
    name = @"X-Axis";
    int * axisState =  &mX;
    input_device_item_add(device,
                          [name UTF8String],
                          axisState,
                          ITEM_ID_XAXIS,
                          mouseAxisGetState);
    
    axis = [mouse xElement];
    name = @"Y-Axis";
    axisState =  &mY;
    input_device_item_add(device,
                          [name UTF8String],
                          axisState,
                          ITEM_ID_YAXIS,
                          mouseAxisGetState);
    
    NSArray * buttons = [mouse buttonElements];
    int buttonCount = MIN([buttons count], MameMouseMaxButtons);
    int i;
    for (i = 0; i < buttonCount; i++)
    {
        DDHidElement * button = [buttons objectAtIndex: i];
        
        NSString * name = [self format: @"Button %d", i+1];
        int * buttonState = &mButtons[i];

        input_device_item_add(device,
                              [name UTF8String],
                              buttonState,
                              (input_item_id)(ITEM_ID_BUTTON1 + i),
                              mouseButtonGetState);
    }
}

#pragma mark -
#pragma mark DDHidMouseDelegate

- (void) ddhidMouse: (DDHidMouse *) mouse xChanged: (SInt32) deltaX;
{
    mX += deltaX;
}

- (void) ddhidMouse: (DDHidMouse *) mouse yChanged: (SInt32) deltaY;
{
    mY += deltaY;
}

- (void) ddhidMouse: (DDHidMouse *) mouse buttonDown: (unsigned) buttonNumber;
{
    mButtons[buttonNumber] = 1;
}

- (void) ddhidMouse: (DDHidMouse *) mouse buttonUp: (unsigned) buttonNumber;
{
    mButtons[buttonNumber] = 0;
}

@end
