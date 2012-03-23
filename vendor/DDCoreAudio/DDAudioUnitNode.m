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

#import "DDAudioUnitNode.h"
#import "DDAudioUnitGraph.h"
#import "DDAudioUnit.h"
#import "DDAudioException.h"

#define THROW_IF DDThrowAudioIfErr

@implementation DDAudioUnitNode

- (id) initWithAUNode: (AUNode) node inGraph: (DDAudioUnitGraph *) graph;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    mNode = node;
    mGraph = graph;
    
    return self;
}

- (void) delloc
{
}

- (AUNode) AUNode;
{
    return mNode;
}

- (DDAudioUnit *) audioUnit;
{
    AudioUnit audioUnit;
    THROW_IF(AUGraphGetNodeInfo([mGraph AUGraph],
                                [self AUNode],
                                NULL, NULL, NULL, &audioUnit));
    return [[[DDAudioUnit alloc] initWithAudioUnit: audioUnit] autorelease];
}

@end
