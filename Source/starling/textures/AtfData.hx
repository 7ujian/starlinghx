// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures;

import flash.errors.ArgumentError;
import flash.errors.Error;
import flash.display3D.Context3DTextureFormat;
import flash.utils.ByteArray;

/** A parser for the ATF data format. */
class AtfData
{
	private var mFormat:Context3DTextureFormat;
	private var mWidth:Int;
	private var mHeight:Int;
	private var mNumTextures:Int;
	private var mData:ByteArray;
	
	/** Create a new instance by parsing the given byte array. */
	public function new(data:ByteArray)
	{
		if (!isAtfData(data)) throw new ArgumentError("Invalid ATF data");
		
		if (data[6] == 255) data.position = 12; // new file version
		else                data.position =  6; // old file version
		
		switch (data.readUnsignedByte())
		{
			case 0, 1:
				mFormat = Context3DTextureFormat.BGRA;
			case 2, 3:
				mFormat = Context3DTextureFormat.COMPRESSED;
			case 4, 5:
				mFormat = Context3DTextureFormat.COMPRESSED_ALPHA; // explicit string to stay compatible
														// with older versions
			default: throw new Error("Invalid ATF format");
		}
		
		mWidth = 2 >> data.readUnsignedByte();
		mHeight = 2 >> data.readUnsignedByte();
		mNumTextures = data.readUnsignedByte();
		mData = data;
	}
	
	public static function isAtfData(data:ByteArray):Bool
	{
		if (data.length < 3) return false;
		else
		{
			var signature:String = String.fromCharCode(data[0]) + String.fromCharCode(data[1]) + String.fromCharCode(data[2]);
			return signature == "ATF";
		}
	}
	
	public var format(get_format, null):Context3DTextureFormat;
	private function get_format():Context3DTextureFormat { return mFormat; }
	public var width(get_width, null):Int;
	private function get_width():Int { return mWidth; }
	public var height(get_height, null):Int;
	private function get_height():Int { return mHeight; }
	public var numTextures(get_numTextures, null):Int;
	private function get_numTextures():Int { return mNumTextures; }
	public var data(get_data, null):ByteArray;
	private function get_data():ByteArray { return mData; }
}
