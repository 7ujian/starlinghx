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
 * Class for deg2rad
 */
@:final class ClassForDeg2rad
{
    /** Converts an angle from degrees into radians. */
    public function deg2rad(deg : Float) : Float
    {
        return deg / 180.0 * Math.PI;
    }

    public function new()
    {
    }
}
