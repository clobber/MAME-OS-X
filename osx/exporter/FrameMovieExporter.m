/*

File: FrameMovieExporter.m

Abstract: Implements the FrameMovieExporter class.

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

#import "FrameMovieExporter.h"

@implementation FrameMovieExporter

- (id) initWithCodec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height options:(ICMCompressionSessionOptionsRef)options
{
	//Make sure client goes through designated initializer
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id) initWithPath:(NSString*)path codec:(CodecType)codec pixelsWide:(unsigned)width pixelsHigh:(unsigned)height options:(ICMCompressionSessionOptionsRef)options
{
	//ICMCompressionSessionOptionsRef	options = [[self class] defaultOptions];
	Boolean							boolean = true;
	OSErr							theError;
	Handle							dataRef;
	OSType							dataRefType;
	
	//Check parameters
	if(![path length]) {
		[self release];
		return nil;
	}
	
	//Customize compression options - We must enable P & B frames explicitely
	/*
	ICMCompressionSessionOptionsSetAllowTemporalCompression(options, true);
	ICMCompressionSessionOptionsSetAllowFrameReordering(options, true);
	ICMCompressionSessionOptionsSetAllowFrameTimeChanges(options, true);
	ICMCompressionSessionOptionsSetDurationsNeeded(options, true);
	ICMCompressionSessionOptionsSetProperty(options, kQTPropertyClass_ICMCompressionSessionOptions, kICMCompressionSessionOptionsPropertyID_Quality, sizeof(CodecQ), &quality);
	*/
	//ICMCompressionSessionOptionsCreateCopy(kCFAllocatorDefault, options, &options);
	ICMCompressionSessionOptionsSetProperty(options, kQTPropertyClass_ICMCompressionSessionOptions, kICMCompressionSessionOptionsPropertyID_AllowAsyncCompletion, sizeof(Boolean), &boolean);
	//[(id)options autorelease];
	
	//Initialize super class
	if(self = [super initWithCodec:codec pixelsWide:width pixelsHigh:height options:options]) {
		//Create movie file
		theError = QTNewDataReferenceFromFullPathCFString((CFStringRef)path, kQTNativeDefaultPathStyle, 0, &dataRef, &dataRefType);
		if(theError) {
			NSLog(@"QTNewDataReferenceFromFullPathCFString() failed with error %i", theError);
			[self release];
			return nil;
		}
		theError = CreateMovieStorage(dataRef, dataRefType, 'TVOD', smCurrentScript, createMovieFileDeleteCurFile, &_dataHandler, &_movie);
		if(theError) {
			NSLog(@"CreateMovieStorage() failed with error %i", theError);
			[self release];
			return nil;
		}
		
		//Add track
		_track = NewMovieTrack(_movie, width << 16, height << 16, 0);
		theError = GetMoviesError();
		if(theError) {
			NSLog(@"NewMovieTrack() failed with error %i", theError);
			[self release];
			return nil;
		}
		
		//Create track media
		_media = NewTrackMedia(_track, VideoMediaType, ICMCompressionSessionGetTimeScale(_compressionSession), 0, 0);
		theError = GetMoviesError();
		if(theError) {
			NSLog(@"NewTrackMedia() failed with error %i", theError);
			[self release];
			return nil;
		}
		
		//Prepare media for editing
		theError = BeginMediaEdits(_media);
		if(theError) {
			NSLog(@"BeginMediaEdits() failed with error %i", theError);
			[self release];
			return nil;
		}
	}
	
	return self; 
}

- (void) dealloc
{
	OSErr							theError;
	
	if(_media) {
		//Make sure all frames have been processed by the compressor
		[self flushFrames];
		
		//End media editing
		theError = EndMediaEdits(_media);
		if(theError)
		NSLog(@"EndMediaEdits() failed with error %i", theError);
		theError = ExtendMediaDecodeDurationToDisplayEndTime(_media, NULL);
		if(theError)
		NSLog(@"ExtendMediaDecodeDurationToDisplayEndTime() failed with error %i", theError);
		
		//Add media to track
		theError = InsertMediaIntoTrack(_track, 0, 0, GetMediaDisplayDuration(_media), fixed1);
		if(theError)
		NSLog(@"InsertMediaIntoTrack() failed with error %i", theError);
		
		//Write movie
		theError = AddMovieToStorage(_movie, _dataHandler);
		if(theError)
		NSLog(@"AddMovieToStorage() failed with error %i", theError);
	}
	
	//Close movie file
	if(_dataHandler)
	CloseMovieStorage(_dataHandler);
	if(_movie)
	DisposeMovie(_movie);
	
	[super dealloc];
}

- (void) doneCompressingFrame:(ICMEncodedFrameRef)frame
{
	OSErr							theError;
	
	//Add frame to track media - Ignore the last frame which will have a duration of 0
	if(ICMEncodedFrameGetDecodeDuration(frame) > 0) {
		theError = AddMediaSampleFromEncodedFrame(_media, frame, NULL);
		if(theError)
		NSLog(@"AddMediaSampleFromEncodedFrame() failed with error %i", theError);
	}
	
	[super doneCompressingFrame:frame];
}

- (BOOL) exportFrame:(CVPixelBufferRef)frame timeStamp:(NSTimeInterval)timestamp
{
	return [super compressFrame:frame timeStamp:timestamp duration:NAN];
}

@end
