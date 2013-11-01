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

import haxe.xml.Fast;
import Std;
import flash.xml.XML;
import flash.Vector;
import haxe.ds.StringMap;
import flash.geom.Rectangle;

/** A texture atlas is a collection of many smaller textures in one big image. This class
 *  is used to access textures from such an atlas.
 *
 *  <p>Using a texture atlas for your textures solves two problems:</p>
 *
 *  <ul>
 *    <li>Whenever you switch between textures, the batching of image objects is disrupted.</li>
 *    <li>Any Stage3D texture has to have side lengths that are powers of two. Starling hides
 *        this limitation from you, but at the cost of additional graphics memory.</li>
 *  </ul>
 *
 *  <p>By using a texture atlas, you avoid both texture switches and the power-of-two
 *  limitation. All textures are within one big "super-texture", and Starling takes care that
 *  the correct part of this texture is displayed.</p>
 *
 *  <p>There are several ways to create a texture atlas. One is to use the atlas generator
 *  script that is bundled with Starling's sibling, the <a href="http://www.sparrow-framework.org">
 *  Sparrow framework</a>. It was only tested in Mac OS X, though. A great multi-platform
 *  alternative is the commercial tool <a href="http://www.texturepacker.com">
 *  Texture Packer</a>.</p>
 *
 *  <p>Whatever tool you use, Starling expects the following file format:</p>
 *
 *  <listing>
 * 	&lt;TextureAtlas imagePath='atlas.png'&gt;
 * 	  &lt;SubTexture name='texture_1' x='0'  y='0' width='50' height='50'/&gt;
 * 	  &lt;SubTexture name='texture_2' x='50' y='0' width='20' height='30'/&gt;
 * 	&lt;/TextureAtlas&gt;
 *  </listing>
 *
 *  <p>If your images have transparent areas at their edges, you can make use of the
 *  <code>frame</code> property of the Texture class. Trim the texture by removing the
 *  transparent edges and specify the original texture size like this:</p>
 *
 *  <listing>
 * 	&lt;SubTexture name='trimmed' x='0' y='0' height='10' width='10'
 * 	    frameX='-10' frameY='-10' frameWidth='30' frameHeight='30'/&gt;
 *  </listing>
 */
class TextureAtlas
{
	private var mAtlasTexture:Texture;
	private var mTextureRegions:StringMap<Rectangle>;
	private var mTextureFrames:StringMap<Rectangle>;

	/** helper objects */
	private static var sNames:Array<String> = new Array<String>();

	/** Create a texture atlas from a texture by parsing the regions from an XML file. */
	public function new(texture:Texture, atlasXml:Xml=null)
	{
		mTextureRegions = new StringMap<Rectangle>();
		mTextureFrames  = new StringMap<Rectangle>();
		mAtlasTexture   = texture;

		if (atlasXml != null)
			parseAtlasXml(atlasXml);
	}

	/** Disposes the atlas texture. */
	public function dispose():Void
	{
		mAtlasTexture.dispose();
	}

	/** This function is called by the constructor and will parse an XML in Starling's
	 *  default atlas file format. Override this method to create custom parsing logic
	 *  (e.g. to support a different file format). */
	private function parseAtlasXml(atlasXml:Xml):Void
	{
		var scale:Float = mAtlasTexture.scale;
		var fast = new Fast(atlasXml);

		for (subTexture in fast.node.TextureAtlas.nodes.SubTexture)
		{
			var name:String        = subTexture.att.name;
			var x:Float           = Std.parseFloat(subTexture.att.x) / scale;
			var y:Float           = Std.parseFloat(subTexture.att.y) / scale;
			var width:Float       = Std.parseFloat(subTexture.att.width) / scale;
			var height:Float      = Std.parseFloat(subTexture.att.height) / scale;
			var frameX:Float      = Std.parseFloat(subTexture.att.frameX) / scale;
			var frameY:Float      = Std.parseFloat(subTexture.att.frameY) / scale;
			var frameWidth:Float  = Std.parseFloat(subTexture.att.frameWidth) / scale;
			var frameHeight:Float = Std.parseFloat(subTexture.att.frameHeight) / scale;

			var region:Rectangle = new Rectangle(x, y, width, height);
			var frame:Rectangle  = frameWidth > 0 && frameHeight > 0 ?
					new Rectangle(frameX, frameY, frameWidth, frameHeight) : null;

			addRegion(name, region, frame);
		}
	}

	/** Retrieves a subtexture by name. Returns <code>null</code> if it is not found. */
	public function getTexture(name:String):Texture
	{
		var region:Rectangle = mTextureRegions.get(name);

		if (region == null) return null;
		else return Texture.fromTexture(mAtlasTexture, region, mTextureFrames.get(name));
	}

	/** Returns all textures that start with a certain string, sorted alphabetically
	 *  (especially useful for "MovieClip"). */
	public function getTextures(prefix:String="", result:Array<Texture> =null):Array<Texture>
	{
		if (result == null) result = new Array<Texture>();

		for (name in getNames(prefix, sNames))
			result.push(getTexture(name));

		sNames.splice(0, sNames.length);
		return result;
	}

	/** Returns all texture names that start with a certain string, sorted alphabetically. */
	public function getNames(prefix:String="", result:Array<String> =null):Array<String>
	{
		if (result == null) result = new Array<String>();

		for (name in mTextureRegions.keys())
			if (name.indexOf(prefix) == 0)
				result.push(name);

		result.sort(sortString);
		return result;
	}

	private function sortString(a:String, b:String):Int
	{
		if (a<b) return -1;
		if (a>b) return 1;
		return 0;
	}

	/** Returns the region rectangle associated with a specific name. */
	public function getRegion(name:String):Rectangle
	{
		return mTextureRegions.get(name);
	}

	/** Returns the frame rectangle of a specific region, or <code>null</code> if that region
	 *  has no frame. */
	public function getFrame(name:String):Rectangle
	{
		return mTextureFrames.get(name);
	}

	/** Adds a named region for a subtexture (described by rectangle with coordinates in
	 *  pixels) with an optional frame. */
	public function addRegion(name:String, region:Rectangle, frame:Rectangle=null):Void
	{
		mTextureRegions.set(name, region);
		mTextureFrames.set(name, frame);
	}

	/** Removes a region with a certain name. */
	public function removeRegion(name:String):Void
	{
		mTextureRegions.remove(name);
		mTextureFrames.remove(name);
	}

	/** The base texture that makes up the atlas. */
	public var texture(get_texture, null):Texture;
	private function get_texture():Texture { return mAtlasTexture; }
}
