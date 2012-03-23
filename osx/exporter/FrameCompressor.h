/*

File: FrameCompressor.h

Abstract: Declares the interface for the FrameCompressor abstract class
which wraps a QuickTime compression session and allows compression of
CVPixelBuffers using arbitrary codecs. The FrameCompressor is initialized
with the compression codec to use, the dimensions of the CVPixelBuffers
to be passed and compression session options (cannot be nil). The methods
+defaultOptions and +userOptions allow to retrieve either default compression
options or prompt the user for compression settings through the standard
QuickTime compression dialog. If the "autosaveName" parameter of the
+userOptions method is not nil, the current compression settings will be
saved / restored from the user defaults). The codec type and framerate
selected by the user are returned as optional parameters. Compressing
frames is achieved by calling -compressFrame and passing the CVPixelBuffer
representing the frame along with optional timestamp and duration (pass
-1.0 if undefined). When the frame is compressed, the -doneCompressingFrame
method is called with the resulting encoded frame (this method is implemented
by subclasses). Use the method -flushFrames to ensure no frames are pending
for compression.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright © 2005 Apple Computer, Inc., All Rights Reserved

*/

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>

@interface FrameCompressor : NSObject
{
	ICMCompressionSessionRef	_compressionSession;
}
+ (ICMCompressionSessionOptionsRef) defaultOptions;
+ (ICMCompressionSessionOptionsRef) userOptions:(CodecType*)outCodecType frameRate:(double*)outFrameRate autosaveName:(NSString*)name;

- (id) initWithCodec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height options:(ICMCompressionSessionOptionsRef)options;
- (BOOL) compressFrame:(CVPixelBufferRef)frame timeStamp:(NSTimeInterval)timestamp duration:(NSTimeInterval)duration;
- (BOOL) flushFrames;

- (void) doneCompressingFrame:(ICMEncodedFrameRef)frame;
@end
