#ifndef CONFIG_H
#define CONFIG_H

#define SDLMAME_DARWIN 1
#define SDLMAME_UNIX 1
#define SDLMAME_MACOSX 1

#if __ppc__
# define PPC_ASM 1
#elif __i386__
# define X86_ASM 1
#endif

#if __LITTLE_ENDIAN__
# define LSB_FIRST 1
#endif

#define INLINE static __inline__
#define asm __asm__
#define PI M_PI
#define strnicmp strncasecmp
#define _scalb scalb
#define CRLF 2

#define PTR64 1

#endif
