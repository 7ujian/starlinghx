package starling.utils;

class StdExt
{
	public static function dynamicCast<T : Dynamic>(target : Dynamic, cls : Class<T>) : T
	{
		if(Std.is(target, cls))
		{
			var ret : T = cast target;
			return ret;
		}
		return null;
	}
}
