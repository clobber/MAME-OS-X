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
