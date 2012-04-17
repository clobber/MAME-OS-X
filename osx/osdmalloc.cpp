//
//  osdmalloc.cpp
//  mameosx
//
//  Created by clobber on 4/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <iostream>

//void *osd_malloc(size_t size);
#ifdef __cplusplus
extern "C" {
#endif
void *osd_malloc(size_t size)
{
    return malloc(size);
}

void osd_free(void *ptr)
{
    free(ptr);
}
    
//============================================================
//  osd_malloc_array
//============================================================
    
void *osd_malloc_array(size_t size)
{
#ifndef MALLOC_DEBUG
    return malloc(size);
#else
#error "MALLOC_DEBUG not yet supported"
#endif
}
    
#ifdef __cplusplus
}
#endif