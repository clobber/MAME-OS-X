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

#ifndef __OSINLINE__
#define __OSINLINE__

#include <libkern/OSAtomic.h>

#include "osd_cpu.h"

//============================================================
//	INLINE FUNCTIONS
//============================================================

#ifdef _MSC_VER

#define vec_mult _vec_mult
INLINE int _vec_mult(int x, int y)
{
    int result;

    __asm {
        mov eax, x
        imul y
        mov result, edx
    }

    return result;
}

#else

#define vec_mult _vec_mult
INLINE int _vec_mult(int x, int y)
{
	int result;

	#ifdef PPC_ASM
	result = x * y;
	#else
	__asm__ (
			"movl  %1    , %0    ; "
			"imull %2            ; "    /* do the multiply */
			"movl  %%edx , %%eax ; "
			:  "=&a" (result)           /* the result has to go in eax */
			:  "mr" (x),                /* x and y can be regs or mem */
			   "mr" (y)
			:  "%edx", "%cc"            /* clobbers edx and flags */
		);
	#endif
	return result;
}

#endif /* _MSC_VER */

#if defined(__i386__) || defined(__x86_64__)

INLINE void osd_yield_processor(void)
{
	__asm__ __volatile__ ( " rep ; nop ;" );
}

#elif defined(__ppc__) || defined (__PPC__) || defined(__ppc64__) || defined(__PPC64__)

INLINE void osd_yield_processor(void)
{
	__asm__ __volatile__ ( " nop \n nop \n" );
}

#endif

#if 0 // Don't do this, yet.  Use the MAME supplied implementations

INLINE INT32 osx_compare_exchange32(INT32 volatile *ptr, INT32 compare, INT32 exchange)
{
    INT32 oldValue = *ptr;
    OSAtomicCompareAndSwap32Barrier(oldValue, exchange, (int32_t *) ptr);
    return oldValue;
}

#ifndef compare_exchange32
#warning Using OSAtomic for compare_exchange32
#define compare_exchange32 osx_compare_exchange32
#endif /* compare_exchange32 */

#endif

#endif /* __OSINLINE__ */
