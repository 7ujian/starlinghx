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


/**
 * Class for getNextPowerOfTwo
 */
class GetNextPowerOfTwo
{
    /** Returns the next power of two that is equal to or bigger than the specified number. */
    public static function getNextPowerOfTwo(number : Int) : Int
    {
        if (number > 0 && (number & (number - 1)) == 0)               // see: http://goo.gl/D9kPj
        	return number;
        else 
        {
            var result : Int = 1;
            while (result < number)result <<= 1;
            return result;
        }
    }

    public function new()
    {
    }
}
