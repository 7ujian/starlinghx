// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.utils;

import starling.errors.AbstractClassError;

/** A utility class containing predefined colors and methods converting between different
 *  color representations. */
class Color
{
    public static inline var WHITE : Int = 0xffffff;
    public static inline var SILVER : Int = 0xc0c0c0;
    public static inline var GRAY : Int = 0x808080;
    public static inline var BLACK : Int = 0x000000;
    public static inline var RED : Int = 0xff0000;
    public static inline var MAROON : Int = 0x800000;
    public static inline var YELLOW : Int = 0xffff00;
    public static inline var OLIVE : Int = 0x808000;
    public static inline var LIME : Int = 0x00ff00;
    public static inline var GREEN : Int = 0x008000;
    public static inline var AQUA : Int = 0x00ffff;
    public static inline var TEAL : Int = 0x008080;
    public static inline var BLUE : Int = 0x0000ff;
    public static inline var NAVY : Int = 0x000080;
    public static inline var FUCHSIA : Int = 0xff00ff;
    public static inline var PURPLE : Int = 0x800080;
    
    /** Returns the alpha part of an ARGB color (0 - 255). */
    public static function getAlpha(color : Int) : Int{return (color >> 24) & 0xff;
    }
    
    /** Returns the red part of an (A)RGB color (0 - 255). */
    public static function getRed(color : Int) : Int{return (color >> 16) & 0xff;
    }
    
    /** Returns the green part of an (A)RGB color (0 - 255). */
    public static function getGreen(color : Int) : Int{return (color >> 8) & 0xff;
    }
    
    /** Returns the blue part of an (A)RGB color (0 - 255). */
    public static function getBlue(color : Int) : Int{return color & 0xff;
    }
    
    /** Creates an RGB color, stored in an unsigned integer. Channels are expected
     *  in the range 0 - 255. */
    public static function rgb(red : Int, green : Int, blue : Int) : Int
    {
        return (red << 16) | (green << 8) | blue;
    }
    
    /** Creates an ARGB color, stored in an unsigned integer. Channels are expected
     *  in the range 0 - 255. */
    public static function argb(alpha : Int, red : Int, green : Int, blue : Int) : Int
    {
        return (alpha << 24) | (red << 16) | (green << 8) | blue;
    }
    
    /** @private */
    public function new()
    {
		throw new AbstractClassError();
    }
}
