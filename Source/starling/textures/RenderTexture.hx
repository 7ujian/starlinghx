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

import starling.textures.DisplayObject;
import starling.textures.Image;
import starling.textures.SubTexture;
import starling.textures.Texture;








import starling.display.DisplayObject;
import starling.display.Image;


/** A RenderTexture is a dynamic texture onto which you can draw any display object.
 * 
 *  <p>After creating a render texture, just call the <code>drawObject</code> method to render 
 *  an object directly onto the texture. The object will be drawn onto the texture at its current
 *  position, adhering its current rotation, scale and alpha properties.</p> 
 *  
 *  <p>Drawing is done very efficiently, as it is happening directly in graphics memory. After 
 *  you have drawn objects onto the texture, the performance will be just like that of a normal 
 *  texture - no matter how many objects you have drawn.</p>
 *  
 *  <p>If you draw lots of objects at once, it is recommended to bundle the drawing calls in 
 *  a block via the <code>drawBundled</code> method, like shown below. That will speed it up 
 *  immensely, allowing you to draw hundreds of objects very quickly.</p>
 *  
 * 	<pre>
 *  renderTexture.drawBundled(function():void
 *  {
 *     for (var i:int=0; i&lt;numDrawings; ++i)
 *     {
 *         image.rotation = (2 &#42; Math.PI / numDrawings) &#42; i;
 *         renderTexture.draw(image);
 *     }   
 *  });
 *  </pre>
 *  
 *  <p>To erase parts of a render texture, you can use any display object like a "rubber" by
 *  setting its blending mode to "BlendMode.ERASE".</p>
 * 
 *  <p>Beware that render textures can't be restored when the Starling's render context is lost.
 *  </p>
 *     
 */
class RenderTexture extends SubTexture
{
    public var isPersistent(get, never) : Bool;

    private var PMA : Bool = true;
    
    private var mActiveTexture : Texture;
    private var mBufferTexture : Texture;
    private var mHelperImage : Image;
    private var mDrawing : Bool;
    private var mBufferReady : Bool;
    private var mSupport : RenderSupport;
    
    /** helper object */
    private static var sClipRect : Rectangle = new Rectangle();
    
    /** Creates a new RenderTexture with a certain size. If the texture is persistent, the
     *  contents of the texture remains intact after each draw call, allowing you to use the
     *  texture just like a canvas. If it is not, it will be cleared before each draw call.
     *  Persistancy doubles the required graphics memory! Thus, if you need the texture only 
     *  for one draw (or drawBundled) call, you should deactivate it. */
    public function new(width : Int, height : Int, persistent : Bool = true, scale : Float = -1)
    {
        mActiveTexture = Texture.empty(width, height, PMA, false, true, scale);
        mActiveTexture.root.onRestore = mActiveTexture.root.clear;
        
        super(mActiveTexture, new Rectangle(0, 0, width, height), true);
        
        var rootWidth : Float = mActiveTexture.root.width;
        var rootHeight : Float = mActiveTexture.root.height;
        
        mSupport = new RenderSupport();
        mSupport.setOrthographicProjection(0, 0, rootWidth, rootHeight);
        
        if (persistent) 
        {
            mBufferTexture = Texture.empty(width, height, PMA, false, true, scale);
            mBufferTexture.root.onRestore = mBufferTexture.root.clear;
            mHelperImage = new Image(mBufferTexture);
            mHelperImage.smoothing = TextureSmoothing.NONE;
        }
    }
    
    /** @inheritDoc */
    override public function dispose() : Void
    {
        mSupport.dispose();
        mActiveTexture.dispose();
        
        if (isPersistent) 
        {
            mBufferTexture.dispose();
            mHelperImage.dispose();
        }
        
        super.dispose();
    }
    
    /** Draws an object into the texture. Note that any filters on the object will currently
     *  be ignored.
     * 
     *  @param object       The object to draw.
     *  @param matrix       If 'matrix' is null, the object will be drawn adhering its 
     *                      properties for position, scale, and rotation. If it is not null,
     *                      the object will be drawn in the orientation depicted by the matrix.
     *  @param alpha        The object's alpha value will be multiplied with this value.
     *  @param antiAliasing This parameter is currently ignored by Stage3D.
     */
    public function draw(object : DisplayObject, matrix : Matrix = null, alpha : Float = 1.0,
            antiAliasing : Int = 0) : Void
    {
        if (object == null)             return;
        
        if (mDrawing) 
            render()
        else 
        drawBundled(render, antiAliasing);
        
        function render() : Void
        {
            mSupport.loadIdentity();
            mSupport.blendMode = object.blendMode;
            
            if (matrix != null)                 mSupport.prependMatrix(matrix)
            else mSupport.transformMatrix(object);
            
            object.render(mSupport, alpha);
        };
    }
    
    /** Bundles several calls to <code>draw</code> together in a block. This avoids buffer 
     *  switches and allows you to draw multiple objects into a non-persistent texture. */
    public function drawBundled(drawingBlock : Function, antiAliasing : Int = 0) : Void
    {
        var context : Context3D = Starling.context;
        if (context == null)             throw new MissingContextError();
        
        // persistent drawing uses double buffering, as Molehill forces us to call 'clear'
        // on every render target once per update.
        
        // switch buffers
        if (isPersistent) 
        {
            var tmpTexture : Texture = mActiveTexture;
            mActiveTexture = mBufferTexture;
            mBufferTexture = tmpTexture;
            mHelperImage.texture = mBufferTexture;
        }
        
        // limit drawing to relevant area
        sClipRect.setTo(0, 0, mActiveTexture.width, mActiveTexture.height);
        
        mSupport.pushClipRect(sClipRect);
        mSupport.renderTarget = mActiveTexture;
        mSupport.clear();
        
        // draw buffer
        if (isPersistent && mBufferReady) 
            mHelperImage.render(mSupport, 1.0)
        else 
        mBufferReady = true;
        
        try
        {
            mDrawing = true;
            
            // draw new objects
            if (drawingBlock != null) 
                drawingBlock();
        };
        finally;{
            mDrawing = false;
            mSupport.finishQuadBatch();
            mSupport.nextFrame();
            mSupport.renderTarget = null;
            mSupport.popClipRect();
        }
    }
    
    /** Clears the texture (restoring full transparency). */
    public function clear() : Void
    {
        var context : Context3D = Starling.context;
        if (context == null)             throw new MissingContextError();
        
        mSupport.renderTarget = mActiveTexture;
        mSupport.clear();
        mSupport.renderTarget = null;
    }
    
    /** Indicates if the texture is persistent over multiple draw calls. */
    private function get_IsPersistent() : Bool{return mBufferTexture != null;
    }
    
    /** @inheritDoc */
    override private function get_Base() : TextureBase{return mActiveTexture.base;
    }
    
    /** @inheritDoc */
    override private function get_Root() : ConcreteTexture{return mActiveTexture.root;
    }
}
