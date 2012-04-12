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

#if defined(__cplusplus)
extern "C" {
#endif

@class MameView;
@class MameInputController;
@class MameAudioController;
@class MameTimingController;
@class MameFileManager;

void osd_set_controller(MameView * controller);
void osd_set_input_controller(MameInputController * inputController);
void osd_set_audio_controller(MameAudioController * audioController);
void osd_set_timing_controller(MameTimingController * timingController);
void osd_set_file_manager(MameFileManager * fileManager);

void osx_osd_core_set_in_app(BOOL in_app);
void osx_osd_core_init(void);
void osx_osd_set_use_autorelease(BOOL use_autorelease);

#if defined(__cplusplus)
}
#endif

//============================================================
//  TYPE DEFINITIONS
//============================================================

typedef void *osd_font;

class osx_osd_interface : public osd_interface
{
public:
	// construction/destruction
	osx_osd_interface();
	virtual ~osx_osd_interface();
    
	// general overridables
	virtual void init(running_machine &machine);
	virtual void update(bool skip_redraw);
    
	// debugger overridables
	virtual void init_debugger();
	virtual void wait_for_debugger(device_t &device, bool firststop);
    
	// audio overridables
	virtual void update_audio_stream(const INT16 *buffer, int samples_this_frame);
	virtual void set_mastervolume(int attenuation);
    
	// input overridables
	virtual void customize_input_type_list(input_type_desc *typelist);
    
	// font overridables
	virtual osd_font font_open(const char *name, int &height);
	virtual void font_close(osd_font font);
	virtual bitmap_t *font_get_bitmap(osd_font font, unicode_char chnum, INT32 &width, INT32 &xoffs, INT32 &yoffs);
    
private:
	static void osd_exit(running_machine &machine);
};
