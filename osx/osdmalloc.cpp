//
//  osdmalloc.cpp
//  mameosx
//
//  Created by clobber on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <iostream>

//void *osd_malloc(size_t size);
void *osd_malloc(size_t size)
{
    return malloc(size);
}