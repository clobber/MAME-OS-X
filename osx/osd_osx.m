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

#include "osdepend.h"
#include "render.h"
#include "unicode.h"
#import "osd_osx.h"
#import "MameView.h"
#import "MameInputController.h"
#import "MameAudioController.h"
#import "MameTimingController.h"
#import "MameFileManager.h"

#include <unistd.h>


static void mame_did_exit(running_machine &machine);
static void mame_did_pause(running_machine * machine, int pause);
static void error_callback(void *param, const char *format, va_list argptr);
static void warning_callback(void *param, const char *format, va_list argptr);
static void info_callback(void *param, const char *format, va_list argptr);
static void debug_callback(void *param, const char *format, va_list argptr);
static void log_callback(void *param, const char *format, va_list argptr);

//-------------------------------------------------
//  osd_interface - constructor
//-------------------------------------------------

osd_interface::osd_interface()
: m_machine(NULL)
{
}


//-------------------------------------------------
//  osd_interface - destructor
//-------------------------------------------------

osd_interface::~osd_interface()
{
}

/******************************************************************************

    Core

******************************************************************************/

static MameView * sController;

void osd_set_controller(MameView * controller)
{
    sController = controller;
    mame_set_output_channel(OUTPUT_CHANNEL_ERROR, error_callback,
                            sController, NULL, NULL);
    mame_set_output_channel(OUTPUT_CHANNEL_WARNING, warning_callback,
                            sController, NULL, NULL);
    mame_set_output_channel(OUTPUT_CHANNEL_INFO, info_callback,
                            sController, NULL, NULL);
    mame_set_output_channel(OUTPUT_CHANNEL_DEBUG, debug_callback,
                            sController, NULL, NULL);
    mame_set_output_channel(OUTPUT_CHANNEL_LOG, log_callback,
                            sController, NULL, NULL);
}

void osx_osd_interface::init(running_machine &machine)
//void osd_init(running_machine *machine)
{
    //add_exit_callback(machine, mame_did_exit);
    //machine->add_notifier(MACHINE_NOTIFY_EXIT, mame_did_exit); //removed, testing
    //add_pause_callback(machine, mame_did_pause);
    
    [sController osd_init: &machine];
    return;
}

static void mame_did_exit(running_machine &machine)
{
    [sController mameDidExit: &machine];
}

static void mame_did_pause(running_machine * machine, int pause)
{
    [sController mameDidPause: machine pause: pause];
}

static void error_callback(void *param, const char *format, va_list argptr)
{
    MameView * controller = (MameView *) param;
    [controller osd_output_error: format arguments: argptr];
}

static void warning_callback(void *param, const char *format, va_list argptr)
{
    MameView * controller = (MameView *) param;
    [controller osd_output_warning: format arguments: argptr];
}

static void info_callback(void *param, const char *format, va_list argptr)
{
    MameView * controller = (MameView *) param;
    [controller osd_output_info: format arguments: argptr];
}

static void debug_callback(void *param, const char *format, va_list argptr)
{
    MameView * controller = (MameView *) param;
    [controller osd_output_debug: format arguments: argptr];
}

static void log_callback(void *param, const char *format, va_list argptr)
{
    MameView * controller = (MameView *) param;
    [controller osd_output_log: format arguments: argptr];
}


/******************************************************************************

    Sound

******************************************************************************/

static MameAudioController * sAudioController;

void osd_set_audio_controller(MameAudioController * audioController)
{
    sAudioController = audioController;
}

void osx_osd_interface::update_audio_stream(const INT16 *buffer, int samples_this_frame)
//void osd_update_audio_stream(running_machine *machine, INT16 *buffer, int samples_this_frame)
{
    //[sAudioController osd_update_audio_stream: machine
    //                                   buffer: buffer
    //                       samples_this_frame: samples_this_frame];
}

void osx_osd_interface::set_mastervolume(int attenuation)
//void osd_set_mastervolume(int attenuation)
{
    [sAudioController osd_set_mastervolume: attenuation];
}


/******************************************************************************

    Controls

******************************************************************************/

static MameInputController * sInputController;

void osd_set_input_controller(MameInputController * inputController)
{
    sInputController = inputController;
}

#if 0
const os_code_info *osd_get_code_list(void)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    const os_code_info * rc = [sInputController osd_get_code_list];
    [pool release];
    return rc;
}

INT32 osd_get_code_value(os_code code)
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    INT32 rc = [sInputController osd_get_code_value: code];
    [pool release];
    return rc;
}
#endif

void osx_osd_interface::customize_input_type_list(input_type_desc *defaults)
//void osd_customize_input_type_list(input_type_desc *defaults)
{
    [sInputController osd_customize_input_type_list: defaults];
}


/******************************************************************************

    Display

******************************************************************************/
void osx_osd_interface::update(bool skip_redraw)
//void osd_update(running_machine *machine, int skip_redraw)
{
    [sController osd_update: skip_redraw];
}

void osd_interface::wait_for_debugger(device_t &device, bool firststop)
//void osd_wait_for_debugger(const device_config *device, int firststop)
{
}

static void link_functions(void)
{
    osd_work_queue_items(0);
}
