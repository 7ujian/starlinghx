package ;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
class Stage3DHelper
{
	#if !flash
	static public function setTo(rect:Rectangle, xa : Float, ya : Float, widtha : Float, heighta : Float) : Void
	{
		rect.x = xa;
		rect.y = ya;
		rect.width = widtha;
		rect.height = heighta;
	}

	static public function copyFrom(rect:Rectangle, sourceRect : Rectangle) : Void
	{
		rect.x = sourceRect.x;
		rect.y = sourceRect.y;
		rect.width = sourceRect.width;
		rect.height = sourceRect.height;
	}

	// TODO
	static public function copyRawDataFrom(matrix3D:Matrix3D, vector : flash.Vector<Float>, index : Int = 0, transpose : Bool = false) : Void
	{
		matrix3D.rawData.splice(index, matrix3D.rawData.length-index);
		matrix3D.rawData = matrix3D.rawData.concat(vector);
	}
	#end
}