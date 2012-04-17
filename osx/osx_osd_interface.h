//
//  osx_osd_interface.h
//  mameosx
//
//  Created by clobber on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//============================================================
//  TYPE DEFINITIONS
//============================================================

typedef void *osd_font;

class osx_osd_interface : public osd_interface
{
public:
    
	// getters
	//running_machine &machine() const { assert(m_machine != NULL); return *m_machine; }
    
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
	//virtual void customize_input_type_list(input_type_desc *typelist);
    virtual void customize_input_type_list(simple_list<input_type_entry> &typelist);
    
	// font overridables
	virtual osd_font font_open(const char *name, int &height);
	virtual void font_close(osd_font font);
	virtual bitmap_t *font_get_bitmap(osd_font font, unicode_char chnum, INT32 &width, INT32 &xoffs, INT32 &yoffs);
    
private:
	static void osd_exit(running_machine &machine);
};
