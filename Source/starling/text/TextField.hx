// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.text;

import flash.text.TextFormatAlign;
import Type;
import flash.Vector;
import Std;
import Std;
import Std;
import Std;
import flash.text.TextFormatAlign;
import haxe.ds.StringMap;
import starling.filters.FragmentFilter;
import flash.errors.ArgumentError;
import flash.errors.Error;
import flash.display.BitmapData;
import flash.display.StageQuality;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.AntiAliasType;
import flash.text.TextFormat;
import flash.utils.Dictionary;

import starling.core.RenderSupport;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.display.QuadBatch;
import starling.display.Sprite;
import starling.events.Event;
import starling.textures.Texture;
import starling.utils.HAlign;
import starling.utils.VAlign;

/** A TextField displays text, either using standard true type fonts or custom bitmap fonts.
 *
 *  <p>You can set all properties you are used to, like the font name and size, a color, the
 *  horizontal and vertical alignment, etc. The border property is helpful during development,
 *  because it lets you see the bounds of the textfield.</p>
 *
 *  <p>There are two types of fonts that can be displayed:</p>
 *
 *  <ul>
 *    <li>Standard TrueType fonts. This renders the text just like a conventional Flash
 *        TextField. It is recommended to embed the font, since you cannot be sure which fonts
 *        are available on the client system, and since this enhances rendering quality.
 *        Simply pass the font name to the corresponding property.</li>
 *    <li>Bitmap fonts. If you need speed or fancy font effects, use a bitmap font instead.
 *        That is a font that has its glyphs rendered to a texture atlas. To use it, first
 *        register the font with the method <code>registerBitmapFont</code>, and then pass
 *        the font name to the corresponding property of the text field.</li>
 *  </ul>
 *
 *  For bitmap fonts, we recommend one of the following tools:
 *
 *  <ul>
 *    <li>Windows: <a href="http://www.angelcode.com/products/bmfont">Bitmap Font Generator</a>
 *       from Angel Code (free). Export the font data as an XML file and the texture as a png
 *       with white characters on a transparent background (32 bit).</li>
 *    <li>Mac OS: <a href="http://glyphdesigner.71squared.com">Glyph Designer</a> from
 *        71squared or <a href="http://http://www.bmglyph.com">bmGlyph</a> (both commercial).
 *        They support Starling natively.</li>
 *  </ul>
 *
 *  <strong>Batching of TextFields</strong>
 *
 *  <p>Normally, TextFields will require exactly one draw call. For TrueType fonts, you cannot
 *  avoid that; bitmap fonts, however, may be batched if you enable the "batchable" property.
 *  This makes sense if you have several TextFields with short texts that are rendered one
 *  after the other (e.g. subsequent children of the same sprite), or if your bitmap font
 *  texture is in your main texture atlas.</p>
 *
 *  <p>The recommendation is to activate "batchable" if it reduces your draw calls (use the
 *  StatsDisplay to check this) AND if the TextFields contain no more than about 10-15
 *  characters (per TextField). For longer texts, the batching would take up more CPU time
 *  than what is saved by avoiding the draw calls.</p>
 */
using Stage3DHelper;

class TextField extends DisplayObjectContainer
{
	// the name container with the registered bitmap fonts
	private static inline var BITMAP_FONT_DATA_NAME:String = "starling.display.TextField.BitmapFonts";

	private var mFontSize:Float;
	private var mColor:UInt;
	private var mText:String;
	private var mFontName:String;
	private var mHAlign:String;
	private var mVAlign:String;
	private var mBold:Bool;
	private var mItalic:Bool;
	private var mUnderline:Bool;
	private var mAutoScale:Bool;
	private var mAutoSize:String;
	private var mKerning:Bool;
	private var mNativeFilters:Array<Dynamic>;
	private var mRequiresRedraw:Bool;
	private var mIsRenderedText:Bool;
	private var mTextBounds:Rectangle;
	private var mBatchable:Bool;

	private var mHitArea:DisplayObject;
	private var mBorder:DisplayObjectContainer;

	private var mImage:Image;
	private var mQuadBatch:QuadBatch;

	// this object will be used for text rendering
	private static var sNativeTextField:flash.text.TextField = new flash.text.TextField();

	/** Create a new text field with the given properties. */
	public function new(width:Int, height:Int, text:String, fontName:String="Verdana",
							  fontSize:Float=12, color:UInt=0x0, bold:Bool=false)
	{
		super();
		mText = text !=null ? text : "";
		mFontSize = fontSize;
		mColor = color;
		mHAlign = HAlign.CENTER;
		mVAlign = VAlign.CENTER;
		mBorder = null;
		mKerning = true;
		mBold = bold;
		mAutoSize = TextFieldAutoSize.NONE;
		this.fontName = fontName;

		mHitArea = new Quad(width, height);
		mHitArea.alpha = 0.0;
		addChild(mHitArea);

		addEventListener(Event.FLATTEN, onFlatten);
	}

	/** Disposes the underlying texture data. */
	public override function dispose():Void
	{
		removeEventListener(Event.FLATTEN, onFlatten);
		if (mImage!=null) mImage.texture.dispose();
		if (mQuadBatch!=null) mQuadBatch.dispose();
		super.dispose();
	}

	private function onFlatten(event:Event):Void
	{
		if (mRequiresRedraw) redraw();
	}

	/** @inheritDoc */
	public override function render(support:RenderSupport, parentAlpha:Float):Void
	{
		if (mRequiresRedraw) redraw();
		super.render(support, parentAlpha);
	}

	/** Forces the text field to be constructed right away. Normally,
	 *  it will only do so lazily, i.e. before being rendered. */
	public function redraw():Void
	{
		if (mRequiresRedraw)
		{
			if (mIsRenderedText) createRenderedContents();
			else                 createComposedContents();

			updateBorder();
			mRequiresRedraw = false;
		}
	}

	// TrueType font rendering

	private function createRenderedContents():Void
	{
		if (mQuadBatch!=null)
		{
			mQuadBatch.removeFromParent(true);
			mQuadBatch = null;
		}

		if (mTextBounds == null)
			mTextBounds = new Rectangle();

		var scale:Float  = Starling.sContentScaleFactor;
		var bitmapData:BitmapData = renderText(scale, mTextBounds);
		#if flash
		var format:Context3DTextureFormat = Reflect.hasField(Context3DTextureFormat, "BGRA_PACKED") ?
			Context3DTextureFormat.BGRA_PACKED : Context3DTextureFormat.BGRA;
		#else
		var format = Context3DTextureFormat.BGRA;
		#end

		mHitArea.width  = bitmapData.width  / scale;
		mHitArea.height = bitmapData.height / scale;

		var texture:Texture = Texture.fromBitmapData(bitmapData, false, false, scale, format);
		texture.root.onRestore = function():Void
		{
			texture.root.uploadBitmapData(renderText(scale, mTextBounds));
		};

		bitmapData.dispose();

		if (mImage == null)
		{
			mImage = new Image(texture);
			mImage.touchable = false;
			addChild(mImage);
		}
		else
		{
			mImage.texture.dispose();
			mImage.texture = texture;
			mImage.readjustSize();
		}
	}

	/** formatText is called immediately before the text is rendered. The intent of formatText
	 *  is to be overridden in a subclass, so that you can provide custom formatting for TextField.
	 *  <code>textField</code> is the flash.text.TextField object that you can specially format;
	 *  <code>textFormat</code> is the default TextFormat for <code>textField</code>.
	 */
	private function formatText(textField:flash.text.TextField, textFormat:TextFormat):Void {}

	private function renderText(scale:Float, resultTextBounds:Rectangle):BitmapData
	{
		var width:Float  = mHitArea.width  * scale;
		var height:Float = mHitArea.height * scale;
		var hAlign:String = mHAlign;
		var vAlign:String = mVAlign;

		if (isHorizontalAutoSize)
		{
			width = Math.POSITIVE_INFINITY;
			hAlign = HAlign.LEFT;
		}
		if (isVerticalAutoSize)
		{
			height = Math.POSITIVE_INFINITY;
			vAlign = VAlign.TOP;
		}

		var textFormat:TextFormat = new TextFormat(mFontName,
			mFontSize * scale, mColor, mBold, mItalic, mUnderline, null, null, untyped(hAlign));
		textFormat.kerning = mKerning;

		sNativeTextField.defaultTextFormat = textFormat;
		sNativeTextField.width = width;
		sNativeTextField.height = height;
		sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
		sNativeTextField.selectable = false;
		sNativeTextField.multiline = true;
		sNativeTextField.wordWrap = true;
		sNativeTextField.text = mText;
		sNativeTextField.embedFonts = true;
		sNativeTextField.filters = mNativeFilters;

		// we try embedded fonts first, non-embedded fonts are just a fallback
		if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
			sNativeTextField.embedFonts = false;

		formatText(sNativeTextField, textFormat);

		if (mAutoScale)
			autoScaleNativeTextField(sNativeTextField);

		var textWidth:Float  = sNativeTextField.textWidth;
		var textHeight:Float = sNativeTextField.textHeight;

		if (isHorizontalAutoSize)
			sNativeTextField.width = width = Math.ceil(textWidth + 5);
		if (isVerticalAutoSize)
			sNativeTextField.height = height = Math.ceil(textHeight + 4);

		// avoid invalid texture size
		if (width  < 1) width  = 1.0;
		if (height < 1) height = 1.0;

		var xOffset:Float = 0.0;
		if (hAlign == HAlign.LEFT)        xOffset = 2; // flash adds a 2 pixel offset
		else if (hAlign == HAlign.CENTER) xOffset = (width - textWidth) / 2.0;
		else if (hAlign == HAlign.RIGHT)  xOffset =  width - textWidth - 2;

		var yOffset:Float = 0.0;
		if (vAlign == VAlign.TOP)         yOffset = 2; // flash adds a 2 pixel offset
		else if (vAlign == VAlign.CENTER) yOffset = (height - textHeight) / 2.0;
		else if (vAlign == VAlign.BOTTOM) yOffset =  height - textHeight - 2;

		var bitmapData:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0x0);
		// TODO, removed int(yOffset), show I use Math.round(yOffset)?
		var drawMatrix:Matrix = new Matrix(1, 0, 0, 1, 0, yOffset-2);

		// Beginning with AIR 3.3, we can force a drawing quality. Since "LOW" produces
		// wrong output oftentimes, we force "MEDIUM" if possible.

		if (Reflect.hasField(bitmapData, "drawWithQuality"))
			Reflect.callMethod(bitmapData, "drawWithQuality", [sNativeTextField, drawMatrix, null, null, null, false, StageQuality.MEDIUM]);
		else
			bitmapData.draw(sNativeTextField, drawMatrix);

		sNativeTextField.text = "";

		// update textBounds rectangle
		resultTextBounds.setTo(xOffset   / scale, yOffset    / scale,
							   textWidth / scale, textHeight / scale);

		return bitmapData;
	}

	private function autoScaleNativeTextField(textField:flash.text.TextField):Void
	{
		var size:Float   = textField.defaultTextFormat.size;
		var maxHeight:Int = Std.int(textField.height - 4);
		var maxWidth:Int  = Std.int(textField.width - 4);

		while (textField.textWidth > maxWidth || textField.textHeight > maxHeight)
		{
			if (size <= 4) break;

			var format:TextFormat = textField.defaultTextFormat;
			format.size = size--;
			textField.setTextFormat(format);
		}
	}

	// bitmap font composition

	private function createComposedContents():Void
	{
		if (mImage!=null)
		{
			mImage.removeFromParent(true);
			mImage = null;
		}

		if (mQuadBatch == null)
		{
			mQuadBatch = new QuadBatch();
			mQuadBatch.touchable = false;
			addChild(mQuadBatch);
		}
		else
			mQuadBatch.reset();

		var bitmapFont:BitmapFont = getBitmapFont(mFontName);
		if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);

		var width:Float  = mHitArea.width;
		var height:Float = mHitArea.height;
		var hAlign:String = mHAlign;
		var vAlign:String = mVAlign;

		if (isHorizontalAutoSize)
		{
			width = Math.POSITIVE_INFINITY;
			hAlign = HAlign.LEFT;
		}
		if (isVerticalAutoSize)
		{
			height = Math.POSITIVE_INFINITY;
			vAlign = VAlign.TOP;
		}

		bitmapFont.fillQuadBatch(mQuadBatch,
			width, height, mText, mFontSize, mColor, hAlign, vAlign, mAutoScale, mKerning);

		mQuadBatch.batchable = mBatchable;

		if (mAutoSize != TextFieldAutoSize.NONE)
		{
			mTextBounds = mQuadBatch.getBounds(mQuadBatch, mTextBounds);

			if (isHorizontalAutoSize)
				mHitArea.width  = mTextBounds.x + mTextBounds.width;
			if (isVerticalAutoSize)
				mHitArea.height = mTextBounds.y + mTextBounds.height;
		}
		else
		{
			// hit area doesn't change, text bounds can be created on demand
			mTextBounds = null;
		}
	}

	// helpers

	private function updateBorder():Void
	{
		if (mBorder == null) return;

		var width:Float  = mHitArea.width;
		var height:Float = mHitArea.height;

		var topLine:Quad    = cast mBorder.getChildAt(0);
		var rightLine:Quad  = cast mBorder.getChildAt(1);
		var bottomLine:Quad = cast mBorder.getChildAt(2);
		var leftLine:Quad   = cast mBorder.getChildAt(3);

		topLine.width    = width; topLine.height    = 1;
		bottomLine.width = width; bottomLine.height = 1;
		leftLine.width   = 1;     leftLine.height   = height;
		rightLine.width  = 1;     rightLine.height  = height;
		rightLine.x  = width  - 1;
		bottomLine.y = height - 1;
		topLine.color = rightLine.color = bottomLine.color = leftLine.color = mColor;
	}

	// properties
	private var isHorizontalAutoSize(get_isHorizontalAutoSize, null):Bool;
	private function get_isHorizontalAutoSize():Bool
	{
		return mAutoSize == TextFieldAutoSize.HORIZONTAL ||
			   mAutoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
	}

	private var isVerticalAutoSize(get_isVerticalAutoSize, null):Bool;
	private function get_isVerticalAutoSize():Bool
	{
		return mAutoSize == TextFieldAutoSize.VERTICAL ||
			   mAutoSize == TextFieldAutoSize.BOTH_DIRECTIONS;
	}

	/** Returns the bounds of the text within the text field. */
	public var textBounds(get_textBounds, null):Rectangle;
	private function get_textBounds():Rectangle
	{
		if (mRequiresRedraw) redraw();
		if (mTextBounds == null) mTextBounds = mQuadBatch.getBounds(mQuadBatch);
		return mTextBounds.clone();
	}

	/** @inheritDoc */
	public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
	{
		if (mRequiresRedraw) redraw();
		return mHitArea.getBounds(targetSpace, resultRect);
	}

	/** @inheritDoc */
	private override function set_width(value:Float):Float
	{
		// different to ordinary display objects, changing the size of the text field should
		// not change the scaling, but make the texture bigger/smaller, while the size
		// of the text/font stays the same (this applies to the height, as well).

		mHitArea.width = value;
		mRequiresRedraw = true;

		return value;
	}

	/** @inheritDoc */
	private override function set_height(value:Float):Float
	{
		mHitArea.height = value;
		mRequiresRedraw = true;
		return value;
	}

	/** The displayed text. */
	public var text(get_text, set_text):String;
	private function get_text():String { return mText; }
	private function set_text(value:String):String
	{
		if (value == null) value = "";
		if (mText != value)
		{
			mText = value;
			mRequiresRedraw = true;
		}
		return value;
	}

	/** The name of the font (true type or bitmap font). */
	public var fontName(get_fontName, set_fontName):String;
	private function get_fontName():String { return mFontName; }
	private function set_fontName(value:String):String
	{
		if (mFontName != value)
		{
			if (value == BitmapFont.MINI && bitmapFonts.exists(value))
				registerBitmapFont(new BitmapFont());

			mFontName = value;
			mRequiresRedraw = true;
			mIsRenderedText = getBitmapFont(value) == null;
		}
		return value;
	}

	/** The size of the font. For bitmap fonts, use <code>BitmapFont.NATIVE_SIZE</code> for
	 *  the original size. */
	public var fontSize(get_fontSize, set_fontSize):Float;
	private function get_fontSize():Float { return mFontSize; }
	private function set_fontSize(value:Float):Float
	{
		if (mFontSize != value)
		{
			mFontSize = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** The color of the text. For bitmap fonts, use <code>Color.WHITE</code> to use the
	 *  original, untinted color. @default black */
	public var color(get_color, set_color):UInt;
	private function get_color():UInt { return mColor; }
	private function set_color(value:UInt):UInt
	{
		if (mColor != value)
		{
			mColor = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** The horizontal alignment of the text. @default center @see starling.utils.HAlign */
	public var hAlign(get_hAlign, set_hAlign):String;
	private function get_hAlign():String { return mHAlign; }
	private function set_hAlign(value:String):String
	{
		if (!HAlign.isValid(value))
			throw new ArgumentError("Invalid horizontal align: " + value);

		if (mHAlign != value)
		{
			mHAlign = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** The vertical alignment of the text. @default center @see starling.utils.VAlign */
	public var vAlign(get_vAlign, set_vAlign):String;
	private function get_vAlign():String { return mVAlign; }
	private function set_vAlign(value:String):String
	{
		if (!VAlign.isValid(value))
			throw new ArgumentError("Invalid vertical align: " + value);

		if (mVAlign != value)
		{
			mVAlign = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** Draws a border around the edges of the text field. Useful for visual debugging.
	 *  @default false */
	public var border(get_border, set_border):Bool;
	private function get_border():Bool { return mBorder != null; }
	private function set_border(value:Bool):Bool
	{
		if (value && mBorder == null)
		{
			mBorder = new Sprite();
			addChild(mBorder);

			for (i in 0...4)
				mBorder.addChild(new Quad(1.0, 1.0));

			updateBorder();
		}
		else if (!value && mBorder != null)
		{
			mBorder.removeFromParent(true);
			mBorder = null;
		}

		return value;
	}

	/** Indicates whether the text is bold. @default false */
	public var bold(get_bold, set_bold):Bool;
	private function get_bold():Bool { return mBold; }
	private function set_bold(value:Bool):Bool
	{
		if (mBold != value)
		{
			mBold = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** Indicates whether the text is italicized. @default false */
	public var italic(get_italic, set_italic):Bool;
	private function get_italic():Bool { return mItalic; }
	private function set_italic(value:Bool):Bool
	{
		if (mItalic != value)
		{
			mItalic = value;
			mRequiresRedraw = true;
		}
		return value;
	}

	/** Indicates whether the text is underlined. @default false */
	public var underline(get_underline, set_underline):Bool;
	private function get_underline():Bool { return mUnderline; }
	private function set_underline(value:Bool):Bool
	{
		if (mUnderline != value)
		{
			mUnderline = value;
			mRequiresRedraw = true;
		}
		return value;
	}

	/** Indicates whether kerning is enabled. @default true */
	public var kerning(get_kerning, set_kerning):Bool;
	private function get_kerning():Bool { return mKerning; }
	private function set_kerning(value:Bool):Bool
	{
		if (mKerning != value)
		{
			mKerning = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** Indicates whether the font size is scaled down so that the complete text fits
	 *  into the text field. @default false */
	public var autoScale(get_autoScale, set_autoScale):Bool;
	private function get_autoScale():Bool { return mAutoScale; }
	private function set_autoScale(value:Bool):Bool
	{
		if (mAutoScale != value)
		{
			mAutoScale = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** Specifies the type of auto-sizing the TextField will do.
	 *  Note that any auto-sizing will make auto-scaling useless. Furthermore, it has
	 *  implications on alignment: horizontally auto-sized text will always be left-,
	 *  vertically auto-sized text will always be top-aligned. @default "none" */
	public var autoSize(get_autoSize, set_autoSize):String;
	private function get_autoSize():String { return mAutoSize; }
	private function set_autoSize(value:String):String
	{
		if (mAutoSize != value)
		{
			mAutoSize = value;
			mRequiresRedraw = true;
		}

		return value;
	}

	/** Indicates if TextField should be batched on rendering. This works only with bitmap
	 *  fonts, and it makes sense only for TextFields with no more than 10-15 characters.
	 *  Otherwise, the CPU costs will exceed any gains you get from avoiding the additional
	 *  draw call. @default false */
	public var batchable(get_batchable, set_batchable):Bool;
	private function get_batchable():Bool { return mBatchable; }
	private function set_batchable(value:Bool):Bool
	{
		mBatchable = value;
		if (mQuadBatch!=null) mQuadBatch.batchable = value;
		return value;
	}

	/** The native Flash BitmapFilters to apply to this TextField.
	 *  Only available when using standard (TrueType) fonts! */
	public var nativeFilters(get_nativeFilters, set_nativeFilters):Array<Dynamic>;
	private function get_nativeFilters():Array<Dynamic> { return mNativeFilters; }
	private function set_nativeFilters(value:Array<Dynamic>) : Array<Dynamic>
	{
		if (!mIsRenderedText)
			throw(new Error("The TextField.nativeFilters property cannot be used on Bitmap fonts."));

		mRequiresRedraw = true;
		return mNativeFilters = value.concat([]);
	}

	/** Makes a bitmap font available at any TextField in the current stage3D context.
	 *  The font is identified by its <code>name</code> (not case sensitive).
	 *  Per default, the <code>name</code> property of the bitmap font will be used, but you
	 *  can pass a custom name, as well. @returns the name of the font. */
	public static function registerBitmapFont(bitmapFont:BitmapFont, name:String=null):String
	{
		if (name == null) name = bitmapFont.name;
		bitmapFonts.set(name.toLowerCase(), bitmapFont);
		return name;
	}

	/** Unregisters the bitmap font and, optionally, disposes it. */
	public static function unregisterBitmapFont(name:String, dispose:Bool=true):Void
	{
		name = name.toLowerCase();

		if (dispose && bitmapFonts.exists(name))
			bitmapFonts.get(name).dispose();

		bitmapFonts.remove(name);
	}

	/** Returns a registered bitmap font (or null, if the font has not been registered).
	 *  The name is not case sensitive. */
	public static function getBitmapFont(name:String):BitmapFont
	{
		return bitmapFonts.get(name.toLowerCase());
	}

	/** Stores the currently available bitmap fonts. Since a bitmap font will only work
	 *  in one Stage3D context, they are saved in Starling's 'contextData' property. */
	private static var bitmapFonts(get_bitmapFonts, null):StringMap<BitmapFont>;
	private static function get_bitmapFonts():StringMap<BitmapFont>
	{
		var fonts:StringMap<BitmapFont> = cast Starling.current.contextData.get(BITMAP_FONT_DATA_NAME);

		if (fonts == null)
		{
			fonts = new StringMap<BitmapFont>();
			Starling.current.contextData.set(BITMAP_FONT_DATA_NAME, fonts);
		}

		return fonts;
	}
}
