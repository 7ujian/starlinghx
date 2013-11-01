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
 * Class for formatString
 */
import Std;
import StringTools;
import flash.utils.RegExp;
@:final class FormatString
{
    // TODO: add number formatting options
    
    /** Formats a String in .Net-style, with curly braces ("{0}"). Does not support any 
     *  number formatting options yet. */
    public static function formatString(format : String, args:Array<Dynamic>) : String
    {
		// TODO
//        for (i in 0...args.length){
//			format = StringTools.replace(format, new RegExp("\\{" + i + "\\}", "g"), Std.string(args[i]));
//        }
        
        return format;
    }

    public function new()
    {
    }
}
