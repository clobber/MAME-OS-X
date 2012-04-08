//
//  MameKeyboard.m
//  mameosx
//
//  Created by Dave Dribin on 10/27/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "MameKeyboard.h"
#import "DDHidLib.h"
#include <IOKit/hid/IOHIDUsageTables.h>

// MAME headers
//#include "driver.h"
#include "emu.h"

typedef struct _os_code_info os_code_info;
struct _os_code_info
{
    const char *name;       /* OS dependant name; 0 terminates the list */
    uint32_t oscode;             /* OS dependant code */
    input_item_id itemId;
};

static os_code_info sKeyboardTranslationTable[];

@interface MameKeyboard (DDHidKeyboardDelegate)

- (void) ddhidKeyboard: (DDHidKeyboard *) keyboard
               keyDown: (unsigned) usageId;

- (void) ddhidKeyboard: (DDHidKeyboard *) keyboard
                 keyUp: (unsigned) usageId;
@end

@implementation MameKeyboard

static INT32 keyboardGetState(void *device_internal, void *item_internal)
{
    MameKeyboard * keyboard = (MameKeyboard *) device_internal;
    if (!(*keyboard->mEnabled))
        return 0;
    
    int key = (int) item_internal;
    return keyboard->mKeyStates[key];
}

- (void) osd_init: (running_machine*) machine;
{
    DDHidKeyboard * keyboard = (DDHidKeyboard *) mDevice;
    [keyboard setDelegate: self];
    
    NSString * name = [NSString stringWithFormat: @"Keyboard %d", mMameTag];
    JRLogInfo(@"Adding keyboard device: %@", name);
    input_device * device = input_device_add(machine,
											 DEVICE_CLASS_KEYBOARD,
                                             [name UTF8String],
                                             self);
    
    
    int i = 0;
    while (sKeyboardTranslationTable[i].name != 0)
    {
        os_code_info * currentKey = &sKeyboardTranslationTable[i];
        input_device_item_add(device,
                              currentKey->name,
                              (void *) currentKey->oscode,
                              currentKey->itemId,
                              keyboardGetState);
        
        i++;
    }
    
    for (i = 0; i < MameKeyboardMaxKeys; i++)
    {
        mKeyStates[i] = 0;
    }
}

@end

@implementation MameKeyboard (DDHidKeyboardDelegate)

- (void) ddhidKeyboard: (DDHidKeyboard *) keyboard
               keyDown: (unsigned) usageId;
{
    mKeyStates[usageId] = 1;
}

- (void) ddhidKeyboard: (DDHidKeyboard *) keyboard
                 keyUp: (unsigned) usageId;
{
    mKeyStates[usageId] = 0;
}

@end

static os_code_info sKeyboardTranslationTable[] =
{
    {"1",       kHIDUsage_Keyboard1,    ITEM_ID_1},
    {"2",       kHIDUsage_Keyboard2,    ITEM_ID_2},
    {"3",       kHIDUsage_Keyboard3,    ITEM_ID_3},
    {"4",       kHIDUsage_Keyboard4,    ITEM_ID_4},
    {"5",       kHIDUsage_Keyboard5,    ITEM_ID_5},
    {"6",       kHIDUsage_Keyboard6,    ITEM_ID_6},
    {"7",       kHIDUsage_Keyboard7,    ITEM_ID_7},
    {"8",       kHIDUsage_Keyboard8,    ITEM_ID_8},
    {"9",       kHIDUsage_Keyboard9,    ITEM_ID_9},
    
    {"A",       kHIDUsage_KeyboardA,    ITEM_ID_A},
    {"B",       kHIDUsage_KeyboardB,    ITEM_ID_B},
    {"C",       kHIDUsage_KeyboardC,    ITEM_ID_C},
    {"D",       kHIDUsage_KeyboardD,    ITEM_ID_D},
    {"E",       kHIDUsage_KeyboardE,    ITEM_ID_E},
    {"F",       kHIDUsage_KeyboardF,    ITEM_ID_F},
    {"G",       kHIDUsage_KeyboardG,    ITEM_ID_G},
    {"H",       kHIDUsage_KeyboardH,    ITEM_ID_H},
    {"I",       kHIDUsage_KeyboardI,    ITEM_ID_I},
    {"J",       kHIDUsage_KeyboardJ,    ITEM_ID_J},
    {"K",       kHIDUsage_KeyboardK,    ITEM_ID_K},
    {"L",       kHIDUsage_KeyboardL,    ITEM_ID_L},
    {"M",       kHIDUsage_KeyboardM,    ITEM_ID_M},
    {"N",       kHIDUsage_KeyboardN,    ITEM_ID_N},
    {"O",       kHIDUsage_KeyboardO,    ITEM_ID_O},
    {"P",       kHIDUsage_KeyboardP,    ITEM_ID_P},
    {"Q",       kHIDUsage_KeyboardQ,    ITEM_ID_Q},
    {"R",       kHIDUsage_KeyboardR,    ITEM_ID_R},
    {"S",       kHIDUsage_KeyboardS,    ITEM_ID_S},
    {"T",       kHIDUsage_KeyboardT,    ITEM_ID_T},
    {"U",       kHIDUsage_KeyboardU,    ITEM_ID_U},
    {"V",       kHIDUsage_KeyboardV,    ITEM_ID_V},
    {"W",       kHIDUsage_KeyboardW,    ITEM_ID_W},
    {"X",       kHIDUsage_KeyboardX,    ITEM_ID_X},
    {"Y",       kHIDUsage_KeyboardY,    ITEM_ID_Y},
    {"Z",       kHIDUsage_KeyboardZ,    ITEM_ID_Z},
    
    {"ESC",     kHIDUsage_KeyboardEscape,       ITEM_ID_ESC},
    {"~",       kHIDUsage_KeyboardGraveAccentAndTilde,
        ITEM_ID_TILDE},
    {"-",       kHIDUsage_KeyboardHyphen,       ITEM_ID_MINUS},
    {"=",       kHIDUsage_KeyboardEqualSign,    ITEM_ID_EQUALS},
    {"Backspace", kHIDUsage_KeyboardDeleteOrBackspace,
        ITEM_ID_BACKSPACE},
    {"Tab",     kHIDUsage_KeyboardTab,          ITEM_ID_TAB},
    {"{",       kHIDUsage_KeyboardOpenBracket,  ITEM_ID_OPENBRACE},
    {"}",       kHIDUsage_KeyboardCloseBracket, ITEM_ID_CLOSEBRACE},
    {"Return",  kHIDUsage_KeyboardReturnOrEnter, ITEM_ID_ENTER},
    {":",       kHIDUsage_KeyboardSemicolon,    ITEM_ID_COLON},
    {"'",       kHIDUsage_KeyboardQuote,        ITEM_ID_QUOTE},
    {"\\",      kHIDUsage_KeyboardBackslash,    ITEM_ID_BACKSLASH},
    // ITEM_ID_BACKSLASH2
    {",",       kHIDUsage_KeyboardComma,        ITEM_ID_COMMA},
    {"Stop",    kHIDUsage_KeyboardStop,         ITEM_ID_STOP},
    {"/",       kHIDUsage_KeyboardSlash,        ITEM_ID_SLASH},
    {"Space",   kHIDUsage_KeyboardSpacebar,     ITEM_ID_SPACE},
    
    {"Insert",  kHIDUsage_KeyboardInsert,       ITEM_ID_INSERT},
    {"Delete",  kHIDUsage_KeyboardDeleteForward, ITEM_ID_DEL},
    {"Home",    kHIDUsage_KeyboardHome,         ITEM_ID_HOME},
    {"End",     kHIDUsage_KeyboardEnd,          ITEM_ID_END},
    {"Page Up", kHIDUsage_KeyboardPageUp,       ITEM_ID_PGUP},
    {"Page Down", kHIDUsage_KeyboardPageDown,   ITEM_ID_PGDN},
    
    {"Up",      kHIDUsage_KeyboardUpArrow,      ITEM_ID_UP},
    {"Down",    kHIDUsage_KeyboardDownArrow,    ITEM_ID_DOWN},
    {"Left",    kHIDUsage_KeyboardLeftArrow,    ITEM_ID_LEFT},
    {"Right",   kHIDUsage_KeyboardRightArrow,   ITEM_ID_RIGHT},
    
    {"F1",      kHIDUsage_KeyboardF1,   ITEM_ID_F1},
    {"F2",      kHIDUsage_KeyboardF2,   ITEM_ID_F2},
    {"F3",      kHIDUsage_KeyboardF3,   ITEM_ID_F3},
    {"F4",      kHIDUsage_KeyboardF4,   ITEM_ID_F4},
    {"F5",      kHIDUsage_KeyboardF5,   ITEM_ID_F5},
    {"F6",      kHIDUsage_KeyboardF6,   ITEM_ID_F6},
    {"F7",      kHIDUsage_KeyboardF7,   ITEM_ID_F7},
    {"F8",      kHIDUsage_KeyboardF8,   ITEM_ID_F8},
    {"F9",      kHIDUsage_KeyboardF9,   ITEM_ID_F9},
    {"F10",     kHIDUsage_KeyboardF10,  ITEM_ID_F10},
    {"F11",     kHIDUsage_KeyboardF11,  ITEM_ID_F11},
    {"F12",     kHIDUsage_KeyboardF12,  ITEM_ID_F12},
    {"F13",     kHIDUsage_KeyboardF13,  ITEM_ID_F13},
    {"F14",     kHIDUsage_KeyboardF14,  ITEM_ID_F14},
    {"F15",     kHIDUsage_KeyboardF15,  ITEM_ID_F15},
    
    {"Keypad 0",    kHIDUsage_Keypad0,  ITEM_ID_0_PAD},
    {"Keypad 1",    kHIDUsage_Keypad1,  ITEM_ID_1_PAD},
    {"Keypad 2",    kHIDUsage_Keypad2,  ITEM_ID_2_PAD},
    {"Keypad 3",    kHIDUsage_Keypad3,  ITEM_ID_3_PAD},
    {"Keypad 4",    kHIDUsage_Keypad4,  ITEM_ID_4_PAD},
    {"Keypad 5",    kHIDUsage_Keypad5,  ITEM_ID_5_PAD},
    {"Keypad 6",    kHIDUsage_Keypad6,  ITEM_ID_6_PAD},
    {"Keypad 7",    kHIDUsage_Keypad7,  ITEM_ID_7_PAD},
    {"Keypad 8",    kHIDUsage_Keypad8,  ITEM_ID_8_PAD},
    {"Keypad 9",    kHIDUsage_Keypad9,  ITEM_ID_9_PAD},
    
    {"Keypad /",    kHIDUsage_KeypadSlash,      ITEM_ID_SLASH_PAD},
    {"Keypad *",    kHIDUsage_KeypadAsterisk,   ITEM_ID_ASTERISK},
    {"Keypad -",    kHIDUsage_KeypadHyphen,     ITEM_ID_MINUS_PAD},
    {"Keypad +",    kHIDUsage_KeypadPlus,       ITEM_ID_PLUS_PAD},
    {"Keypad DEL",  kHIDUsage_KeypadNumLock,    ITEM_ID_DEL_PAD},
    {"Keypad Enter", kHIDUsage_KeypadEnter,     ITEM_ID_ENTER_PAD},
    
    {"PRTSCR",      kHIDUsage_KeyboardPrintScreen,  ITEM_ID_PRTSCR},
    {"Pause",       kHIDUsage_KeyboardPause,        ITEM_ID_PAUSE},
    
    {"L. Control",  kHIDUsage_KeyboardLeftControl,  ITEM_ID_LCONTROL},
    {"L. Option",   kHIDUsage_KeyboardLeftAlt,      ITEM_ID_LALT},
    // {"L. Command",  kHIDUsage_KeyboardLeftGUI,      ITEM_ID_LWIN},
    {"L. Shift",    kHIDUsage_KeyboardLeftShift,    ITEM_ID_LSHIFT},
    
    {"R. Control",  kHIDUsage_KeyboardRightControl, ITEM_ID_RCONTROL},
    {"R. Option",   kHIDUsage_KeyboardRightAlt,     ITEM_ID_RALT},
    // {"R. Command",  kHIDUsage_KeyboardRightGUI,     ITEM_ID_RWIN},
    {"R. Shift",    kHIDUsage_KeyboardRightShift,   ITEM_ID_RSHIFT},
    
    {0,         0,      0}
};
