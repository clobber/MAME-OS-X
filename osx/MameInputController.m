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

#import "MameInputController.h"
#import "MameKeyboard.h"
#import "MameMouse.h"
#import "MameJoystick.h"
#import "DDHidLib.h"

// MAME headers
//#include "driver.h"
#include "emu.h"

@interface MameInputControllerPrivate : NSObject
{
  @public
    NSMutableArray * mDeviceNames;
    NSMutableArray * mDevices;
}

- (id) init;

@end

@implementation MameInputControllerPrivate

- (id) init;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mDeviceNames = [[NSMutableArray alloc] init];
    mDevices = [[NSMutableArray alloc] init];
    
    return self;
}

//=========================================================== 
// dealloc
//=========================================================== 
- (void) dealloc
{
    [mDeviceNames release];
    [mDevices release];
    
    mDeviceNames = nil;
    mDevices = nil;
    [super dealloc];
}

@end


@interface MameInputController (Private)

- (void) addAllKeyboards: (running_machine *) machine;
- (void) addAllMice: (running_machine *) machine;
- (void) addAllJoysticks: (running_machine *) machine;

@end

@interface MameInputController (DDHidJoystickDelegate)

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

@implementation MameInputController

- (id) init
{
    if ([super init] == nil)
        return nil;
    
    p = [[MameInputControllerPrivate alloc] init];
    mEnabled = NO;
    mDevices = [[NSMutableArray alloc] init];
    
    return self;
}

- (void) dealloc
{
    [p release];
    [mDevices release];
    
    p = nil;
    mDevices = nil;
    
    [super dealloc];
}

- (void) osd_init: (running_machine *) machine;
{
    [p->mDevices removeAllObjects];
    [p->mDeviceNames removeAllObjects];

    [mDevices removeAllObjects];
    [self addAllKeyboards: machine];
    [self addAllMice: machine];
    [self addAllJoysticks: machine];
}

- (void) gameFinished;
{
    [mDevices makeObjectsPerformSelector: @selector(stopListening)];
    [mDevices removeAllObjects];

    [p->mDevices makeObjectsPerformSelector: @selector(stopListening)];
    [p->mDevices removeAllObjects];
    [p->mDeviceNames removeAllObjects];
}

// Todo: Fix keyboard enabled static hack
static BOOL sEnabled = NO;

- (BOOL) enabled;
{
    return mEnabled;
}

- (void) setEnabled: (BOOL) enabled;
{
    mEnabled = enabled;
}

- (void) osd_customize_input_type_list: (input_type_desc *) defaults;
{
	input_type_desc * idef = NULL;

    // loop over all the defaults
	for (idef = defaults; idef = idef->next; idef->next != NULL) {
	
        switch (idef->type) {
            case IPT_UI_FAST_FORWARD:
                idef->token = "FAST_FORWARD";
                idef->name = "Fast Forward";
                input_seq_set_1(&idef->seq[SEQ_TYPE_STANDARD], KEYCODE_PGDN);
                break;
        }
	}
}

@end

@implementation MameInputController (Private)

- (void) addAllKeyboards: (running_machine*) machine;
{
    int keyboardTag = 0;
    NSArray * keyboards = [DDHidKeyboard allKeyboards];
    int keyboardCount = [keyboards count];
    int keyboardNumber;
    for (keyboardNumber = 0; keyboardNumber < keyboardCount; keyboardNumber++)
    {
        DDHidKeyboard * hidKeyboard = [keyboards objectAtIndex: keyboardNumber];
        JRLogInfo(@"Found keyboard: %@ (%@)",
                  [hidKeyboard productName], [hidKeyboard manufacturer]);
        MameKeyboard * keyboard = [[MameKeyboard alloc] initWithDevice: hidKeyboard
                                                               mameTag: keyboardTag
                                                               enabled: &mEnabled];
        [keyboard autorelease];
        if (![keyboard tryStartListening])
        {
            JRLogInfo(@"Could not start listening to keyboard, skipping");
            continue;
        }

        [mDevices addObject: keyboard];
        [keyboard osd_init: machine];
        keyboardTag++;
    }
}

- (void) addAllMice: (running_machine*) machine;
{
    int mouseTag = 0;
    NSArray * mice = [DDHidMouse allMice];
    int mouseCount = [mice count];
    int mouseNumber;
    for (mouseNumber = 0; mouseNumber < mouseCount; mouseNumber++)
    {
        DDHidMouse * hidMouse = [mice objectAtIndex: mouseNumber];
        NSArray * buttons = [hidMouse buttonElements];
        JRLogInfo(@"Found mouse: %@ (%@), %d button(s)",
                  [hidMouse productName], [hidMouse manufacturer],
                  [buttons count]);
        MameMouse * mouse = [[MameMouse alloc] initWithDevice: hidMouse
                                                      mameTag: mouseTag
                                                      enabled: &mEnabled];
        [mouse autorelease];
        if (![mouse tryStartListening])
        {
            JRLogInfo(@"Could not start listening to mouse, skipping");
            continue;
        }
        
        [mDevices addObject: mouse];
        [mouse osd_init: machine];
        mouseTag++;
    }
}


- (void) addAllJoysticks: (running_machine *) machine;
{
    int joystickTag = 0;
    NSArray * joysticks = [DDHidJoystick allJoysticks];
    int joystickCount = [joysticks count];
    int joystickNumber;
    for (joystickNumber = 0; joystickNumber < joystickCount; joystickNumber++)
    {
        DDHidJoystick * hidJoystick = [joysticks objectAtIndex: joystickNumber];
        NSArray * buttons = [hidJoystick buttonElements];
        JRLogInfo(@"Found joystick: %@ (%@), %d stick(s), %d button(s)",
                  [hidJoystick productName], [hidJoystick manufacturer],
                  [hidJoystick countOfSticks], [buttons count]);
        MameJoystick * joystick = [[MameJoystick alloc] initWithDevice: hidJoystick
                                                               mameTag: joystickTag
                                                               enabled: &mEnabled];
        [joystick autorelease];
        if (![joystick tryStartListening])
        {
            JRLogInfo(@"Could not start listening to joystick, skipping");
            continue;
        }
        
        [mDevices addObject: joystick];
        [joystick osd_init: machine];
        joystickTag++;
    }
}

@end
