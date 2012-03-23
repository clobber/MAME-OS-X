/*
 * Copyright (c) 2006 Dave Dribin
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

#import "DDAudioUnit.h"
#import "DDAudioException.h"
#import <AudioUnit/AUCocoaUIView.h>
#import <CoreAudioKit/CoreAudioKit.h>
#import "DDAudioUnitPreset.h"

#define THROW_IF DDThrowAudioIfErr

@interface DDAudioUnit (Private)

#if 0
- (OSStatus) getProperty: (AudioUntPropertyID) propertyId
                   scope: (AudioUnitScope) scope
                 element: (AudioUnitElement) element
                    data: (void *) data
                    size: (UInt32 *) size;

- (OSStatus) setProperty: (AudioUntPropertyID) propertyId
                   scope: (AudioUnitScope) scope
                 element: (AudioUnitElement) element
                    data: (void *) data
                    size: (UInt32) size;
#endif

- (void) getFactoryPresets;

@end

@implementation DDAudioUnit

- (id) initWithAudioUnit: (AudioUnit) audioUnit;
{
    self = [super init];
    if (self == nil)
        return nil;

    mAudioUnit = audioUnit;
    
    return self;
}

- (AudioUnit) AudioUnit;
{
    return mAudioUnit;
}


- (void) setRenderCallback: (AURenderCallback) callback
                   context: (void *) context;
{
    AURenderCallbackStruct input;
    input.inputProc = callback;
    input.inputProcRefCon = context;
    THROW_IF(AudioUnitSetProperty([self AudioUnit],
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &input, sizeof(input)));
}

- (void) setBypass: (BOOL) bypass;
{
    UInt32 bypassInt = bypass? 1 : 0;
    THROW_IF(AudioUnitSetProperty([self AudioUnit],
                                  kAudioUnitProperty_BypassEffect, 
                                  0,
                                  0, 
                                  &bypassInt, 
                                  sizeof(bypassInt)));
}


- (BOOL) bypass;
{
    UInt32 bypassInt;
    UInt32 size = sizeof(bypassInt);
    THROW_IF(AudioUnitGetProperty([self AudioUnit],
                                  kAudioUnitProperty_BypassEffect, 
                                  0,
                                  0, 
                                  &bypassInt, &size));
    return (bypassInt == 0)? NO : YES;
}

- (void) setStreamFormatWithDescription:
    (const AudioStreamBasicDescription *) streamFormat;
{
    THROW_IF(AudioUnitSetProperty([self AudioUnit],
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  streamFormat,
                                  sizeof(AudioStreamBasicDescription)));
}

#pragma mark -
#pragma mark Presets

- (NSArray *) factoryPresets;
{
    if (mFactoryPresets == nil)
        [self getFactoryPresets];
    
    return mFactoryPresets;
}

- (unsigned) indexOfFactoryPreset: (DDAudioUnitPreset *) presetToFind;
{
    unsigned result = NSNotFound;
    unsigned i;
    for (i = 0; i < [mFactoryPresets count]; i++)
    {
        DDAudioUnitPreset * preset = [mFactoryPresets objectAtIndex: i];
        if ([preset isEqualToPreset: presetToFind])
        {
            result = i;
            break;
        }
    }
    return result;
}

- (DDAudioUnitPreset *) presentPreset;
{
    AUPreset preset;
    UInt32 size = sizeof(preset);
    OSStatus err = AudioUnitGetProperty(mAudioUnit,
                                        kAudioUnitProperty_PresentPreset,
                                        0, 0, &preset, &size);
    if (err == kAudioUnitErr_InvalidProperty)
        return nil;
    THROW_IF(err);
    
    return [[[DDAudioUnitPreset alloc] initWithAUPreset: preset] autorelease];
}

- (void) setPresentPreset: (DDAudioUnitPreset *) presentPreset;
{
    AUPreset preset = [presentPreset AUPreset];
    OSStatus err = AudioUnitSetProperty(mAudioUnit,
                                        kAudioUnitProperty_PresentPreset,
                                        0, 0, &preset, sizeof(preset));
    if (err == kAudioUnitErr_InvalidProperty)
        return;
    THROW_IF(err);
}


- (unsigned) presentPresetIndex;
{
    return [self indexOfFactoryPreset: [self presentPreset]];
}

- (void) setPresentPresetIndex: (unsigned) presentPresetIndex;
{
    [self setPresentPreset: [mFactoryPresets objectAtIndex: presentPresetIndex]];
}

#pragma mark -
#pragma mark View

- (NSView *) createViewWithSize: (NSSize) size;
{
    NSView * view = nil;
    view = [self createCustomCocoaViewWithSize: size];
    if (view == nil)
    {
        view = [self createGenericView];
    }
    return view;
}

- (BOOL) hasCustomCocoaView;
{
    UInt32 dataSize   = 0;
    Boolean isWritable = 0;
    THROW_IF(AudioUnitGetPropertyInfo(mAudioUnit,
                                      kAudioUnitProperty_CocoaUI,
                                      kAudioUnitScope_Global,
                                      0, &dataSize, &isWritable));
    
    return (dataSize > 0);
}

- (NSView *) createCustomCocoaViewWithSize: (NSSize) size;
{
    NSView * theView = nil;
    UInt32 dataSize = 0;
    Boolean isWritable = 0;
    
    OSStatus err = AudioUnitGetPropertyInfo(mAudioUnit,
                                            kAudioUnitProperty_CocoaUI,
                                            kAudioUnitScope_Global, 
                                            0, &dataSize, &isWritable);
    
    if (err != noErr)
        return nil;

    unsigned numberOfClasses =
        (dataSize - sizeof(CFURLRef)) / sizeof(CFStringRef);
    if (numberOfClasses == 0)
        return nil;

    // If we have the property, then allocate storage for it.
    AudioUnitCocoaViewInfo * viewInfo =
        (AudioUnitCocoaViewInfo*) malloc(dataSize);
    THROW_IF(AudioUnitGetProperty(mAudioUnit, 
                                  kAudioUnitProperty_CocoaUI,
                                  kAudioUnitScope_Global, 0,
                                  viewInfo, &dataSize));
    
    // Extract useful data.
    NSString * viewClassName = (NSString *)(viewInfo->mCocoaAUViewClass[0]);
    NSString * path = (NSString *)
        (CFURLCopyPath(viewInfo->mCocoaAUViewBundleLocation));
    NSBundle * viewBundle = [NSBundle bundleWithPath: [path autorelease]];
    Class viewClass = [viewBundle classNamed: viewClassName];
    
    if ([viewClass conformsToProtocol: @protocol(AUCocoaUIBase)])
    {
        id<AUCocoaUIBase> factory = [[[viewClass alloc] init] autorelease];
        theView = [factory uiViewForAudioUnit: mAudioUnit
                                     withSize: size];
    }
    
    // Delete the cocoa view info stuff.
    if (viewInfo)
    {
        int i;
        for(i = 0; i < numberOfClasses; i++)
            CFRelease(viewInfo->mCocoaAUViewClass[i]);
        
        CFRelease(viewInfo->mCocoaAUViewBundleLocation);
        free(viewInfo);
    }
    
    return theView;
}

- (AUGenericView *) createGenericView;
{
    return [[[AUGenericView alloc] initWithAudioUnit: mAudioUnit] autorelease];
}

@end

@implementation DDAudioUnit (Private)

- (void) getFactoryPresets;
{
    mFactoryPresets = [[NSMutableArray alloc] init];

    CFArrayRef factoryPresets;
    UInt32 size = sizeof(factoryPresets);
    OSStatus err = AudioUnitGetProperty(mAudioUnit,
                                        kAudioUnitProperty_FactoryPresets, 
                                        0,
                                        0, 
                                        &factoryPresets, &size);
    if (err == kAudioUnitErr_InvalidProperty)
        return;
    THROW_IF(err);
    
    CFIndex count = CFArrayGetCount(factoryPresets);
    int i;
    for (i = 0; i < count; i++)
    {
        const AUPreset * preset = CFArrayGetValueAtIndex(factoryPresets, i);
        DDAudioUnitPreset * objcPreset = [[DDAudioUnitPreset alloc] initWithAUPreset: *preset];
        [mFactoryPresets addObject: objcPreset];
    }
    CFRelease(factoryPresets);
}

@end
