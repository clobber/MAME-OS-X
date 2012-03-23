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

#import <QuartzCore/QuartzCore.h>

extern "C" {
    
#include "render.h"
    
}


// Force inlining, even for non-optimized builds.  The performance impact is just
// too high.
#define inline inline __attribute__((always_inline))

template <typename PixelType>
class BaseMamePixelIterator
{
  public:
    void init(const render_texinfo * texture, int row)
    {
        mCurrentPixel = (PixelType *) texture->base;
        mCurrentPixel += row * texture->rowpixels;
        mPalette = texture->palette;
    }
    
    void inline next()
    {
        mCurrentPixel++;
    }
    
protected:
    PixelType * mCurrentPixel;
    const rgb_t * mPalette;
};

typedef BaseMamePixelIterator<UINT16> Mame16BitPixelIterator;
typedef BaseMamePixelIterator<UINT32> Mame32BitPixelIterator;

class MamePalette16PixelIterator : public Mame16BitPixelIterator
{
public:
    UINT32 inline argb_value() const
    {
        return 0xff000000 | mPalette[*mCurrentPixel];
    }    
};

class MameARGB32PixelIterator : public Mame32BitPixelIterator
{
public:    
    UINT32 inline argb_value() const
    {
        return *mCurrentPixel;
    }
};

class MamePaletteRGB15PixelIterator : public Mame16BitPixelIterator
{
public:
    UINT32 inline argb_value() const
    {
        UINT16 pix = *mCurrentPixel;
        return
            0xff000000 |
            mPalette[0x40 + ((pix >> 10) & 0x1f)] |
            mPalette[0x20 + ((pix >>  5) & 0x1f)] |
            mPalette[0x00 + ((pix >>  0) & 0x1f)];
    }
};    

class MameRGB15PixelIterator : public Mame16BitPixelIterator
{
public:
    UINT32 inline argb_value() const
    {
        UINT16 pix = *mCurrentPixel;
        UINT32 color =
            ((pix & 0x7c00) << 9) |
            ((pix & 0x03e0) << 6) |
            ((pix & 0x001f) << 3);
        
        return 0xff000000 | color | ((color >> 5) & 0x070707);
    }
};

class MamePaletteRGB32PixelIterator : public Mame32BitPixelIterator
{
public:
    UINT32 inline argb_value() const
    {
        UINT32 sourceValue = *mCurrentPixel;
        return
            0xff000000 |
            mPalette[0x200 + RGB_RED(sourceValue)] |
            mPalette[0x100 + RGB_GREEN(sourceValue)] |
            mPalette[0x000 + RGB_BLUE(sourceValue)];
    }
};

class MameRGB32PixelIterator : public Mame32BitPixelIterator
{
public:
    UINT32 inline argb_value() const
    {
        return 0xff000000 | *mCurrentPixel;
    }
};

template <typename PixelIterator>
class MameTexture
{
public:
    typedef PixelIterator Iterator;

    MameTexture(const render_texinfo * texture)
        : mTexture(texture)
    {
    }
    
    int width() const
    {
        return mTexture->width;
    }
    
    int height() const
    {
        return mTexture->height;
    }
    
    Iterator iteratorForRow(int row)
    {
        Iterator i;
        i.init(mTexture, row);
        return i;
    }
    
protected:
    const render_texinfo * mTexture;
};

typedef MameTexture<MamePalette16PixelIterator> MamePalette16Texture;
typedef MameTexture<MameARGB32PixelIterator> MameARGB32Texture;
typedef MameTexture<MamePaletteRGB32PixelIterator> MamePaletteRGB32Texture;
typedef MameTexture<MameRGB32PixelIterator> MameRGB32Texture;
typedef MameTexture<MamePaletteRGB15PixelIterator> MamePaletteRGB15Texture;
typedef MameTexture<MameRGB15PixelIterator> MameRGB15Texture;

class BGRA32PixelIterator
{
public:
#if __BIG_ENDIAN__
    static const int kPixelFormat = k32BGRAPixelFormat;
#else
    static const int kPixelFormat = k32ARGBPixelFormat;
#endif
    
    BGRA32PixelIterator(UINT32 * base)
        : mCurrentPixel(base)
    {
    }
    
    template <typename MamePixelIterator>
    void inline copy_from(const MamePixelIterator & src)
    {
        UINT32 argb_value = src.argb_value();
        *mCurrentPixel =
            (argb_value & 0x000000ff) << 24 |
            (argb_value & 0x0000ff00) <<  8 |
            (argb_value & 0x00ff0000) >>  8 |
            (argb_value & 0xff000000) >> 24;
    }
    
    void inline next()
    {
        mCurrentPixel++;
    }
    
private:
    UINT32 * mCurrentPixel;
};


class ARGB32PixelIterator
{
public:
#if __BIG_ENDIAN__
    static const int kPixelFormat = k32ARGBPixelFormat;
#else
    static const int kPixelFormat = k32BGRAPixelFormat;
#endif

    ARGB32PixelIterator(UINT32 * base)
        : mCurrentPixel(base)
    {
    }
        
    template <typename MamePixelIterator>
    void inline copy_from(const MamePixelIterator & src)
    {
        *mCurrentPixel = src.argb_value();
    }
    
    void inline next()
    {
        mCurrentPixel++;
    }
    
private:
    UINT32 * mCurrentPixel;
};

template <typename PixelIterator>
class Generic32PixelBuffer
{
public:
    typedef PixelIterator Iterator;
    
    static const int kPixelFormat = PixelIterator::kPixelFormat;
    
    Generic32PixelBuffer(void * base, size_t bytesPerRow)
        : mBase(base), mBytesPerRow(bytesPerRow)
    {
    }
    
    Iterator iteratorForRow(int row)
    {
        UINT8 * startAddress = (UINT8 *) mBase;
        startAddress += row * mBytesPerRow;
        return Iterator((UINT32 *) startAddress);
    }
    
private:
    void * mBase;
    size_t mBytesPerRow;
};

typedef Generic32PixelBuffer<ARGB32PixelIterator> ARGB32PixelBuffer;
typedef Generic32PixelBuffer<BGRA32PixelIterator> BGRA32PixelBuffer;

template <typename SourceType, typename DestType>
inline void convertTexture(SourceType & source, DestType & dest)
{
    int height = source.height();
    int width = source.width();
    
    for (int y = 0; y < height; y++)
    {
        typename SourceType::Iterator sourceIterator = source.iteratorForRow(y);
        typename DestType::Iterator destIterator = dest.iteratorForRow(y);
        
        for (int x = 0; x < width; x++)
        {
            destIterator.copy_from(sourceIterator);
            sourceIterator.next();
            destIterator.next();
        }
    }
};


#if 1
// ARGB32 is faster on OS X
typedef ARGB32PixelBuffer PixelBuffer;
#else
typedef BGRA32PixelBuffer PixelBuffer;
#endif


#undef inline
