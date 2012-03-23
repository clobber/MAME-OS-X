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

#import "DDAudioComponent.h"
#import "DDAudioException.h"

#define THROW_IF DDThrowAudioIfErr

@implementation DDAudioComponent

+ (NSArray *) componentsMatchingType: (OSType) type
                             subType: (OSType) subType
                        manufacturer: (OSType) manufacturer;
{
    ComponentDescription description;
    description.componentType = type;
    description.componentSubType = subType;
    description.componentManufacturer = manufacturer;
    description.componentFlags = 0;
    description.componentFlagsMask = 0;
    
    return [self componentsMatchingDescription: &description];
}

+ (NSArray *) componentsMatchingDescription:
    (ComponentDescription *) description;
{
    long componentCount = CountComponents(description);
    NSMutableArray * components =
        [NSMutableArray arrayWithCapacity: componentCount];
    Component current = 0;
    do
    {
        NSAutoreleasePool * loopPool = [[NSAutoreleasePool alloc] init];
        current = FindNextComponent(current, description);
        if (current != 0)
        {
            DDAudioComponent * component =
            [[DDAudioComponent alloc] initWithComponent: current];
            [components addObject: component];
            [component release];
        }
        [loopPool release];
    } while (current != 0);
    
    return components;
}

+ (void) printComponents;
{
    NSArray * components = [self componentsMatchingType: kAudioUnitType_Effect
                                                subType: 0
                                           manufacturer: 0];
    NSLog(@"component count: %d", [components count]);
    
    NSEnumerator * e = [components objectEnumerator];
    DDAudioComponent * component;
    while (component = [e nextObject])
    {
        ComponentDescription description = [component ComponentDescription];
        NSString * type = (NSString *)
            UTCreateStringForOSType(description.componentType);
        NSString * subType = (NSString *)
            UTCreateStringForOSType(description.componentSubType);
        NSString * manufacturer = (NSString *)
            UTCreateStringForOSType(description.componentManufacturer);
        
        NSLog(@"Compoment %@ by %@: %@ %@ %@", [component name],
              [component manufacturer], type, subType, manufacturer);
        
        [type release];
        [subType release];
        [manufacturer release];
    }
}

- (id) initWithComponent: (Component) component;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mComponent = component;
    mManufacturer = @"";
    mName = @"";
    
    Handle h1 = NewHandle(4);
    THROW_IF(GetComponentInfo(component, &mDescription, h1, NULL, NULL));
    
    NSString * fullName = (NSString *)
        CFStringCreateWithPascalString(NULL, (const unsigned char*)*h1, kCFStringEncodingMacRoman);
    DisposeHandle(h1);
    
    NSRange colonRange = [fullName rangeOfString: @":"];
    if (colonRange.location != NSNotFound)
    {
        mManufacturer = [fullName substringToIndex: colonRange.location];
        mName = [fullName substringFromIndex: colonRange.location + 1];
        mName = [mName stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
        
        [mManufacturer retain];
        [mName retain];
    }
    else
    {
        mManufacturer = @"";
        mName = [fullName copy];
    }
    
    [fullName release];
    
    return self;
}

- (Component) Component;
{
    return mComponent;
}

- (ComponentDescription) ComponentDescription;
{
    return mDescription;
}

- (NSString *) manufacturer;
{
    return mManufacturer;
}

- (NSString *) name;
{
    return mName;
}


@end
