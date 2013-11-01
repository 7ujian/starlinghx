// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display;

import nme.errors.ArgumentError;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Rectangle;
import starling.display.Sprite;
import starling.display.TextField;
import starling.display.Texture;
import starling.display.Touch;
import starling.display.TouchEvent;

import nme.geom.Rectangle;
import nme.ui.Mouse;
import nme.ui.MouseCursor;

import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import starling.textures.Texture;
import starling.utils.HAlign;
import starling.utils.VAlign;

/** Dispatched when the user triggers the button. Bubbles. */
@:meta(Event(name="triggered",type="starling.events.Event"))


/** A simple button composed of an image and, optionally, text.
 *  
 *  <p>You can pass a texture for up- and downstate of the button. If you do not provide a down 
 *  state, the button is simply scaled a little when it is touched.
 *  In addition, you can overlay a text on the button. To customize the text, almost the 
 *  same options as those of text fields are provided. In addition, you can move the text to a 
 *  certain position with the help of the <code>textBounds</code> property.</p>
 *  
 *  <p>To react on touches on a button, there is special <code>triggered</code>-event type. Use
 *  this event instead of normal touch events - that way, users can cancel button activation
 *  by moving the mouse/finger away from the button before releasing.</p> 
 */
class Button extends DisplayObjectContainer
{
    public var scaleWhenDown(get, set) : Float;
    public var alphaWhenDisabled(get, set) : Float;
    public var enabled(get, set) : Bool;
    public var text(get, set) : String;
    public var fontName(get, set) : String;
    public var fontSize(get, set) : Float;
    public var fontColor(get, set) : Int;
    public var fontBold(get, set) : Bool;
    public var upState(get, set) : Texture;
    public var downState(get, set) : Texture;
    public var textVAlign(get, set) : String;
    public var textHAlign(get, set) : String;
    public var textBounds(get, set) : Rectangle;

    private static inline var MAX_DRAG_DIST : Float = 50;
    
    private var mUpState : Texture;
    private var mDownState : Texture;
    
    private var mContents : Sprite;
    private var mBackground : Image;
    private var mTextField : TextField;
    private var mTextBounds : Rectangle;
    
    private var mScaleWhenDown : Float;
    private var mAlphaWhenDisabled : Float;
    private var mEnabled : Bool;
    private var mIsDown : Bool;
    private var mUseHandCursor : Bool;
    
    /** Creates a button with textures for up- and down-state or text. */
    public function new(upState : Texture, text : String = "", downState : Texture = null)
    {
        if (upState == null)             throw new ArgumentError("Texture cannot be null");
        
        mUpState = upState;
        mDownState = (downState != null) ? downState : upState;
        mBackground = new Image(upState);
        mScaleWhenDown = (downState != null) ? 1.0 : 0.9;
        mAlphaWhenDisabled = 0.5;
        mEnabled = true;
        mIsDown = false;
        mUseHandCursor = true;
        mTextBounds = new Rectangle(0, 0, upState.width, upState.height);
        
        mContents = new Sprite();
        mContents.addChild(mBackground);
        addChild(mContents);
        addEventListener(TouchEvent.TOUCH, onTouch);
        
        this.text = text;
    }
    
    private function resetContents() : Void
    {
        mIsDown = false;
        mBackground.texture = mUpState;
        mContents.x = mContents.y = 0;
        mContents.scaleX = mContents.scaleY = 1.0;
    }
    
    private function createTextField() : Void
    {
        if (mTextField == null) 
        {
            mTextField = new TextField(mTextBounds.width, mTextBounds.height, "");
            mTextField.vAlign = VAlign.CENTER;
            mTextField.hAlign = HAlign.CENTER;
            mTextField.touchable = false;
            mTextField.autoScale = true;
            mTextField.batchable = true;
        }
        
        mTextField.width = mTextBounds.width;
        mTextField.height = mTextBounds.height;
        mTextField.x = mTextBounds.x;
        mTextField.y = mTextBounds.y;
    }
    
    private function onTouch(event : TouchEvent) : Void
    {
        Mouse.cursor = ((mUseHandCursor && mEnabled && event.interactsWith(this))) ? 
                MouseCursor.BUTTON : MouseCursor.AUTO;
        
        var touch : Touch = event.getTouch(this);
        if (!mEnabled || touch == null)             return;
        
        if (touch.phase == TouchPhase.BEGAN && !mIsDown) 
        {
            mBackground.texture = mDownState;
            mContents.scaleX = mContents.scaleY = mScaleWhenDown;
            mContents.x = (1.0 - mScaleWhenDown) / 2.0 * mBackground.width;
            mContents.y = (1.0 - mScaleWhenDown) / 2.0 * mBackground.height;
            mIsDown = true;
        }
        else if (touch.phase == TouchPhase.MOVED && mIsDown) 
        {
            // reset button when user dragged too far away after pushing
            var buttonRect : Rectangle = getBounds(stage);
            if (touch.globalX < buttonRect.x - MAX_DRAG_DIST ||
                touch.globalY < buttonRect.y - MAX_DRAG_DIST ||
                touch.globalX > buttonRect.x + buttonRect.width + MAX_DRAG_DIST ||
                touch.globalY > buttonRect.y + buttonRect.height + MAX_DRAG_DIST) 
            {
                resetContents();
            }
        }
        else if (touch.phase == TouchPhase.ENDED && mIsDown) 
        {
            resetContents();
            dispatchEventWith(Event.TRIGGERED, true);
        }
    }
    
    /** The scale factor of the button on touch. Per default, a button with a down state 
      * texture won't scale. */
    private function get_ScaleWhenDown() : Float{return mScaleWhenDown;
    }
    private function set_ScaleWhenDown(value : Float) : Float{mScaleWhenDown = value;
        return value;
    }
    
    /** The alpha value of the button when it is disabled. @default 0.5 */
    private function get_AlphaWhenDisabled() : Float{return mAlphaWhenDisabled;
    }
    private function set_AlphaWhenDisabled(value : Float) : Float{mAlphaWhenDisabled = value;
        return value;
    }
    
    /** Indicates if the button can be triggered. */
    private function get_Enabled() : Bool{return mEnabled;
    }
    private function set_Enabled(value : Bool) : Bool
    {
        if (mEnabled != value) 
        {
            mEnabled = value;
            mContents.alpha = (value) ? 1.0 : mAlphaWhenDisabled;
            resetContents();
        }
        return value;
    }
    
    /** The text that is displayed on the button. */
    private function get_Text() : String{return (mTextField != null) ? mTextField.text : "";
    }
    private function set_Text(value : String) : String
    {
        if (value.length == 0) 
        {
            if (mTextField != null) 
            {
                mTextField.text = value;
                mTextField.removeFromParent();
            }
        }
        else 
        {
            createTextField();
            mTextField.text = value;
            
            if (mTextField.parent == null) 
                mContents.addChild(mTextField);
        }
        return value;
    }
    
    /** The name of the font displayed on the button. May be a system font or a registered 
      * bitmap font. */
    private function get_FontName() : String{return (mTextField != null) ? mTextField.fontName : "Verdana";
    }
    private function set_FontName(value : String) : String
    {
        createTextField();
        mTextField.fontName = value;
        return value;
    }
    
    /** The size of the font. */
    private function get_FontSize() : Float{return (mTextField != null) ? mTextField.fontSize : 12;
    }
    private function set_FontSize(value : Float) : Float
    {
        createTextField();
        mTextField.fontSize = value;
        return value;
    }
    
    /** The color of the font. */
    private function get_FontColor() : Int{return (mTextField != null) ? mTextField.color : 0x0;
    }
    private function set_FontColor(value : Int) : Int
    {
        createTextField();
        mTextField.color = value;
        return value;
    }
    
    /** Indicates if the font should be bold. */
    private function get_FontBold() : Bool{return (mTextField != null) ? mTextField.bold : false;
    }
    private function set_FontBold(value : Bool) : Bool
    {
        createTextField();
        mTextField.bold = value;
        return value;
    }
    
    /** The texture that is displayed when the button is not being touched. */
    private function get_UpState() : Texture{return mUpState;
    }
    private function set_UpState(value : Texture) : Texture
    {
        if (mUpState != value) 
        {
            mUpState = value;
            if (!mIsDown)                 mBackground.texture = value;
        }
        return value;
    }
    
    /** The texture that is displayed while the button is touched. */
    private function get_DownState() : Texture{return mDownState;
    }
    private function set_DownState(value : Texture) : Texture
    {
        if (mDownState != value) 
        {
            mDownState = value;
            if (mIsDown)                 mBackground.texture = value;
        }
        return value;
    }
    
    /** The vertical alignment of the text on the button. */
    private function get_TextVAlign() : String{return mTextField.vAlign;
    }
    private function set_TextVAlign(value : String) : String
    {
        createTextField();
        mTextField.vAlign = value;
        return value;
    }
    
    /** The horizontal alignment of the text on the button. */
    private function get_TextHAlign() : String{return mTextField.hAlign;
    }
    private function set_TextHAlign(value : String) : String
    {
        createTextField();
        mTextField.hAlign = value;
        return value;
    }
    
    /** The bounds of the textfield on the button. Allows moving the text to a custom position. */
    private function get_TextBounds() : Rectangle{return mTextBounds.clone();
    }
    private function set_TextBounds(value : Rectangle) : Rectangle
    {
        mTextBounds = value.clone();
        createTextField();
        return value;
    }
    
    /** Indicates if the mouse cursor should transform into a hand while it's over the button. 
     *  @default true */
    override private function get_UseHandCursor() : Bool{return mUseHandCursor;
    }
    override private function set_UseHandCursor(value : Bool) : Bool{mUseHandCursor = value;
        return value;
    }
}
