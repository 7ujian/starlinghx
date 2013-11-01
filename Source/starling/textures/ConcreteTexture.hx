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

import Reflect;
import Std;
import Std;
import Std;
import Reflect;
import flash.display3D.Context3DTextureFormat;
import Std;
import starling.utils.GetNextPowerOfTwo;
import starling.utils.GetNextPowerOfTwo;
import flash.errors.Error;
import Std;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.textures.TextureBase;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.utils.ByteArray;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.errors.MissingContextError;
import starling.events.Event;
import starling.utils.Color;


/** A ConcreteTexture wraps a Stage3D texture object, storing the properties of the texture. */
class ConcreteTexture extends Texture
{
	private var mOnRestore:Void->Void;
	private var mDataUploaded:Bool;

	/** helper object */
	private static var sOrigin:Point = new Point();

	/** Creates a ConcreteTexture object from a TextureBase, storing information about size,
	 *  mip-mapping, and if the channels contain premultiplied alpha values. */
	public function new(base:TextureBase, format:Context3DTextureFormat, width:Int, height:Int,
									mipMapping:Bool, premultipliedAlpha:Bool,
									optimizedForRenderTexture:Bool=false,
									scale:Float=1)
	{
		mScale = scale <= 0 ? 1.0 : scale;
		mRoot = this;
		mBase = base;
		mFormat = format;
		mWidth = width/mScale;
		mHeight = height/mScale;
		mMipMapping = mipMapping;
		mPremultipliedAlpha = premultipliedAlpha;
		mOptimizedForRenderTexture = optimizedForRenderTexture;
		mOnRestore = null;
		mDataUploaded = false;
	}

	/** Disposes the TextureBase object. */
	public override function dispose():Void
	{
		if (mBase!=null) mBase.dispose();
		this.onRestore = null; // removes event listener
		super.dispose();
	}

	// texture data upload

	/** Uploads a bitmap to the texture. The existing contents will be replaced.
	 *  If the size of the bitmap does not match the size of the texture, the bitmap will be
	 *  cropped or filled up with transparent pixels */
	public function uploadBitmap(bitmap:Bitmap):Void
	{
		uploadBitmapData(bitmap.bitmapData);
	}

	/** Uploads bitmap data to the texture. The existing contents will be replaced.
	 *  If the size of the bitmap does not match the size of the texture, the bitmap will be
	 *  cropped or filled up with transparent pixels */
	public function uploadBitmapData(data:BitmapData):Void
	{
		var potData:BitmapData = null;
		var widthInt:Int = Std.int(mWidth);
		var heightInt:Int = Std.int(mHeight);

		if (data.width != widthInt || data.height != heightInt)
		{
			potData = new BitmapData(widthInt, heightInt, true, 0);
			potData.copyPixels(data, data.rect, sOrigin);
			data = potData;
		}

		if (Std.is(mBase, flash.display3D.textures.Texture))
		{
			var potTexture:flash.display3D.textures.Texture =
				cast (mBase, flash.display3D.textures.Texture);

			potTexture.uploadFromBitmapData(data);

			if (mMipMapping && data.width > 1 && data.height > 1)
			{
				var currentWidth:Int  = data.width  >> 1;
				var currentHeight:Int = data.height >> 1;
				var level:Int = 1;
				var canvas:BitmapData = new BitmapData(currentWidth, currentHeight, true, 0);
				var transform:Matrix = new Matrix(.5, 0, 0, .5);
				var bounds:Rectangle = new Rectangle();

				while (currentWidth >= 1 || currentHeight >= 1)
				{
					bounds.width = currentWidth; bounds.height = currentHeight;
					canvas.fillRect(bounds, 0);
					canvas.draw(data, transform, null, null, null, true);
					potTexture.uploadFromBitmapData(canvas, level++);
					transform.scale(0.5, 0.5);
					currentWidth  = currentWidth  >> 1;
					currentHeight = currentHeight >> 1;
				}

				canvas.dispose();
			}
		}
		else // if (nativeTexture is RectangleTexture)
		{
			Reflect.callMethod(mBase, "uploadFromBitmapData", [data]);
		}

		if (potData!=null) potData.dispose();
		mDataUploaded = true;
	}

	/** Uploads ATF data from a ByteArray to the texture. Note that the size of the
	 *  ATF-encoded data must be exactly the same as the original texture size.
	 *
	 *  <p>The 'async' parameter may be either a boolean value or a callback function.
	 *  If it's <code>false</code> or <code>null</code>, the texture will be decoded
	 *  synchronously and will be visible right away. If it's <code>true</code> or a function,
	 *  the data will be decoded asynchronously. The texture will remain unchanged until the
	 *  upload is complete, at which time the callback function will be executed. This is the
	 *  expected function definition: <code>function(texture:Texture):Void;</code></p>
	 */
	public function uploadAtfData(data:ByteArray, offset:Int=0, isAsync:Bool=false, callback:Void->Void =null):Void
	{
		var eventType = "textureReady"; // defined here for backwards compatibility

		var self:ConcreteTexture = this;
		var potTexture:flash.display3D.textures.Texture =
			  cast (mBase, flash.display3D.textures.Texture);

		potTexture.uploadCompressedTextureFromByteArray(data, offset, isAsync);
		mDataUploaded = true;

		function onTextureReady(event:Dynamic):Void
		{
			potTexture.removeEventListener(eventType, onTextureReady);

			if (callback != null)
			{
				callback();
				// TODO: only one type callback since there is not callback.length
//				if (callback.length == 1) callback(self);
//				else callback();
			}
		}

		if (isAsync && callback != null)
			potTexture.addEventListener(eventType, onTextureReady);
	}

	// texture backup (context loss)

	private function onContextCreated(event:Event):Void
	{
		// recreate the underlying texture & restore contents
		createBase();
		mOnRestore();

		// if no texture has been uploaded above, we init the texture with transparent pixels.
		if (!mDataUploaded) clear();
	}

	/** Recreates the underlying Stage3D texture object with the same dimensions and attributes
	 *  as the one that was passed to the constructor. You have to upload new data before the
	 *  texture becomes usable again. Beware: this method does <strong>not</strong> dispose
	 *  the current base. */
	@:allow(starling) function createBase():Void
	{
		var context:Context3D = Starling.sContext;
		var widthInt:Int = Std.int(mWidth);
		var heightInt:Int = Std.int(mHeight);

		var isPot:Bool = widthInt  == GetNextPowerOfTwo.getNextPowerOfTwo(widthInt) &&
		heightInt == GetNextPowerOfTwo.getNextPowerOfTwo(heightInt);

		if (isPot)
			mBase = context.createTexture(widthInt, heightInt, mFormat,
										  mOptimizedForRenderTexture);
		else
			mBase = Reflect.callMethod(context, "createRectangleTexture", [widthInt, heightInt, mFormat,
													  mOptimizedForRenderTexture]);

		mDataUploaded = false;
	}

	/** Clears the texture with a certain color and alpha value. The previous contents of the
	 *  texture is wiped out. Beware: this method resets the render target to the back buffer;
	 *  don't call it from within a render method. */
	public function clear(color:UInt=0x0, alpha:Float=0.0):Void
	{
		var context:Context3D = Starling.sContext;
		if (context == null) throw new MissingContextError();

		if (mPremultipliedAlpha && alpha < 1.0)
			color = Color.rgb(Std.int(Color.getRed(color)   * alpha),
							  Std.int(Color.getGreen(color) * alpha),
							  Std.int(Color.getBlue(color)  * alpha));

		context.setRenderToTexture(mBase);

		// we wrap the clear call in a try/catch block as a workaround for a problem of
		// FP 11.8 plugin/projector: calling clear on a compressed texture doesn't work there
		// (while it *does* work on iOS + Android).

		try { RenderSupport.static_clear(color, alpha); }
		catch (e:Error) {}

		context.setRenderToBackBuffer();
		mDataUploaded = true;
	}

	// properties

	/** Indicates if the base texture was optimized for being used in a render texture. */
	public var optimizedForRenderTexture(get_optimizedForRenderTexture, null):Bool;
	private function get_optimizedForRenderTexture():Bool { return mOptimizedForRenderTexture; }

	/** If Starling's "handleLostContext" setting is enabled, the function that you provide
	 *  here will be called after a context loss. On execution, a new base texture will
	 *  already have been created; however, it will be empty. Call one of the "upload..."
	 *  methods from within the callbacks to restore the actual texture data. */
	public var onRestore(get_onRestore, set_onRestore):Void->Void;
	private function get_onRestore():Void->Void { return mOnRestore; }
	private function set_onRestore(value:Void->Void):Void->Void
	{
		Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);

		if (Starling.handleLostContext && value != null)
		{
			mOnRestore = value;
			Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		}
		else mOnRestore = null;

		return mOnRestore;
	}


//	/** @inheritDoc */
//	private override function get_width():Float  { return mWidth / mScale;  }
//
//	/** @inheritDoc */
//	private override function get_height():Float { return mHeight / mScale; }
//
//	/** @inheritDoc */
//	private override function get_base():TextureBase { return mBase; }
//
//	/** @inheritDoc */
//	private override function get_root():ConcreteTexture { return this; }
//
//	/** @inheritDoc */
//	private override function get_format():Context3DTextureFormat { return mFormat; }
//
//	/** @inheritDoc */
//	private override function get_nativeWidth():Float { return mWidth; }
//
//	/** @inheritDoc */
//	private override function get_nativeHeight():Float { return mHeight; }
//
//	/** The scale factor, which influences width and height properties. */
//	private override function get_scale():Float { return mScale; }
//
//	/** @inheritDoc */
//	private override function get_mipMapping():Bool { return mMipMapping; }
//
//	/** @inheritDoc */
//	private override function get_premultipliedAlpha():Bool { return mPremultipliedAlpha; }
}
