// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.textures;

import Std;
import flash.display3D.Context3DTextureFormat;
import flash.Vector;
import flash.display3D.textures.TextureBase;
import flash.geom.Point;
import flash.geom.Rectangle;

import starling.utils.VertexData;

/** A SubTexture represents a section of another texture. This is achieved solely by 
 *  manipulation of texture coordinates, making the class very efficient. 
 *
 *  <p><em>Note that it is OK to create subtextures of subtextures.</em></p>
 */ 
class SubTexture extends Texture
{
	private var mParent:Texture;
	private var mClipping:Rectangle;
	private var mRootClipping:Rectangle;
	private var mOwnsParent:Bool;
	
	/** Helper object. */
	private static var sTexCoords:Point = new Point();
	
	/** Creates a new subtexture containing the specified region (in points) of a parent 
	 *  texture. If 'ownsParent' is true, the parent texture will be disposed automatically
	 *  when the subtexture is disposed. */
	public function new(parentTexture:Texture, region:Rectangle,
							   ownsParent:Bool=false)
	{
		mParent = parentTexture;
		mOwnsParent = ownsParent;
		
		if (region == null) setClipping(new Rectangle(0, 0, 1, 1));
		else setClipping(new Rectangle(region.x / parentTexture.width,
									   region.y / parentTexture.height,
									   region.width / parentTexture.width,
									   region.height / parentTexture.height));

		mBase =  mParent.base;
		mRoot = mParent.root;
		mFormat = mParent.format;
		mWidth = mParent.width * mClipping.width;
		mHeight = mParent.height * mClipping.height;
		mNativeWidth = mParent.nativeWidth * mClipping.width;
		mNativeHeight = mParent.nativeHeight * mClipping.height;
		mMipMapping = mParent.mipMapping;
		mPremultipliedAlpha = mParent.premultipliedAlpha;
		mScale = mParent.scale;
	}
	
	/** Disposes the parent texture if this texture owns it. */
	public override function dispose():Void
	{
		if (mOwnsParent) mParent.dispose();
		super.dispose();
	}
	
	private function setClipping(value:Rectangle):Void
	{
		mClipping = value;
		mRootClipping = value.clone();


		var parentTexture:SubTexture = Std.is(mParent, SubTexture)?cast(mParent, SubTexture):null;
		while (parentTexture!=null)
		{
			var parentClipping:Rectangle = parentTexture.mClipping;
			mRootClipping.x = parentClipping.x + mRootClipping.x * parentClipping.width;
			mRootClipping.y = parentClipping.y + mRootClipping.y * parentClipping.height;
			mRootClipping.width  *= parentClipping.width;
			mRootClipping.height *= parentClipping.height;
			parentTexture = Std.is(parentTexture.mParent, SubTexture)?cast(parentTexture.mParent, SubTexture):null;
		}
	}
	
	/** @inheritDoc */
	public override function adjustVertexData(vertexData:VertexData, vertexID:Int, count:Int):Void
	{
		super.adjustVertexData(vertexData, vertexID, count);
		
		var clipX:Float = mRootClipping.x;
		var clipY:Float = mRootClipping.y;
		var clipWidth:Float  = mRootClipping.width;
		var clipHeight:Float = mRootClipping.height;
		var endIndex:Int = vertexID + count;
		
		for (i in vertexID...endIndex)
		{
			vertexData.getTexCoords(i, sTexCoords);
			vertexData.setTexCoords(i, clipX + sTexCoords.x * clipWidth,
									   clipY + sTexCoords.y * clipHeight);
		}
	}

	/** @inheritDoc */
	public override function adjustTexCoords(texCoords:Vector<Float>,
											 startIndex:Int=0, stride:Int=0, count:Int=-1):Void
	{
		if (count < 0)
			count = Std.int((texCoords.length - startIndex - 2) / (stride + 2) + 1);
		
		var index:Int = startIndex;
		for (i in 0...count)
		{
			texCoords[index] = mRootClipping.x + texCoords[index] * mRootClipping.width;
			index += 1;
			texCoords[index] = mRootClipping.y + texCoords[index] * mRootClipping.height;
			index += 1 + stride;
		}
	}
	
	/** The texture which the subtexture is based on. */ 
	public var parent(get_parent, null):Texture;
	private function get_parent():Texture { return mParent; }
	
	/** Indicates if the parent texture is disposed when this object is disposed. */
	public var ownsParent(get_ownsParent, null):Bool;
	private function get_ownsParent():Bool { return mOwnsParent; }
	
	/** The clipping rectangle, which is the region provided on initialization 
	 *  scaled into [0.0, 1.0]. */
	public var clipping(get_clipping, null):Rectangle;
	private function get_clipping():Rectangle { return mClipping.clone(); }
	
//	/** @inheritDoc */
//	private override function get_base():TextureBase { return mParent.base; }
//
//	/** @inheritDoc */
//	private override function get_root():ConcreteTexture { return mParent.root; }
//
//	/** @inheritDoc */
//	private override function get_format():Context3DTextureFormat { return mParent.format; }
//
//	/** @inheritDoc */
//	private override function get_width():Float { return mParent.width * mClipping.width; }
//
//	/** @inheritDoc */
//	private override function get_height():Float { return mParent.height * mClipping.height; }
//
//	/** @inheritDoc */
//	private override function get_nativeWidth():Float { return mParent.nativeWidth * mClipping.width; }
//
//	/** @inheritDoc */
//	private override function get_nativeHeight():Float { return mParent.nativeHeight * mClipping.height; }
//
//	/** @inheritDoc */
//	private override function get_mipMapping():Bool { return mParent.mipMapping; }
//
//	/** @inheritDoc */
//	private override function get_premultipliedAlpha():Bool { return mParent.premultipliedAlpha; }
//
//	/** @inheritDoc */
//	private override function get_scale():Float { return mParent.scale; }
//
}
