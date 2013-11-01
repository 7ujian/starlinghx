// =================================================================================================
//
//	Starling Framework
//	Copyright 2013 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.filters;

import starling.filters.FragmentFilter;
import starling.filters.Matrix3D;
import starling.filters.Point;
import starling.filters.VertexBuffer3D;

import nme.display.BitmapDataChannel;


import nme.display3d.Context3DTextureFormat;
import nme.display3d.Context3DVertexBufferFormat;

import nme.display3d.VertexBuffer3D;
import nme.geom.Matrix3D;
import nme.geom.Point;

import starling.core.RenderSupport;


import starling.utils.FormatString;

/** The DisplacementMapFilter class uses the pixel values from the specified texture (called
 *  the displacement map) to perform a displacement of an object. You can use this filter 
 *  to apply a warped or mottled effect to any object that inherits from the DisplayObject 
 *  class. 
 *
 *  <p>The filter uses the following formula:</p>
 *  <listing>dstPixel[x, y] = srcPixel[x + ((componentX(x, y) - 128) &#42; scaleX) / 256, 
 *                      y + ((componentY(x, y) - 128) &#42; scaleY) / 256)]
 *  </listing>
 *  
 *  <p>Where <code>componentX(x, y)</code> gets the componentX property color value from the 
 *  map texture at <code>(x - mapPoint.x, y - mapPoint.y)</code>.</p>
 */
class DisplacementMapFilter extends FragmentFilter
{
    public var componentX(get, set) : Int;
    public var componentY(get, set) : Int;
    public var scaleX(get, set) : Float;
    public var scaleY(get, set) : Float;
    public var mapTexture(get, set) : Texture;
    public var mapPoint(get, set) : Point;
    public var repeat(get, set) : Bool;

    private var mMapTexture : Texture;
    private var mMapPoint : Point;
    private var mComponentX : Int;
    private var mComponentY : Int;
    private var mScaleX : Float;
    private var mScaleY : Float;
    private var mRepeat : Bool;
    
    private var mShaderProgram : Program3D;
    private var mMapTexCoordBuffer : VertexBuffer3D;
    
    /** Helper objects */
    private static var sOneHalf : Array<Float> = [0.5, 0.5, 0.5, 0.5];
    private static var sMapTexCoords : Array<Float> = [0, 0, 1, 0, 0, 1, 1, 1];
    private static var sMatrix : Matrix3D = new Matrix3D();
    private static var sMatrixData : Array<Float> = 
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    
    /** Creates a new displacement map filter that uses the provided map texture. */
    public function new(mapTexture : Texture, mapPoint : Point = null,
            componentX : Int = 0, componentY : Int = 0,
            scaleX : Float = 0.0, scaleY : Float = 0.0,
            repeat : Bool = false)
    {
        mMapTexture = mapTexture;
        mMapPoint = new Point();
        mComponentX = componentX;
        mComponentY = componentY;
        mScaleX = scaleX;
        mScaleY = scaleY;
        this.mapPoint = mapPoint;
        
        super();
    }
    
    /** @inheritDoc */
    override public function dispose() : Void
    {
        if (mMapTexCoordBuffer != null)             mMapTexCoordBuffer.dispose();
        super.dispose();
    }
    
    /** @private */
    override private function createPrograms() : Void
    {
        // the texture coordinates for the map texture are uploaded via a separate buffer
        if (mMapTexCoordBuffer != null)             mMapTexCoordBuffer.dispose();
        mMapTexCoordBuffer = Starling.context.createVertexBuffer(4, 2);
        
        var target : Starling = Starling.current;
        var mapFlags : String = RenderSupport.getTextureLookupFlags(
                mapTexture.format, mapTexture.mipMapping, mapTexture.repeat);
        var inputFlags : String = RenderSupport.getTextureLookupFlags(
                Context3DTextureFormat.BGRA, false, mRepeat);
        var programName : String = formatString("DMF_m{0}_i{1}", mapFlags, inputFlags);
        
        if (target.hasProgram(programName)) 
        {
            mShaderProgram = target.getProgram(programName);
        }
        else 
        {
            // vc0-3: mvpMatrix
            // va0:   vertex position
            // va1:   input texture coords
            // va2:   map texture coords
            
            var vertexShader : String = [
                    "m44  op, va0, vc0",   // 4x4 matrix transform to output space  
                    "mov  v0, va1",   // pass input texture coordinates to fragment program  
                    "mov  v1, va2"  // pass map texture coordinates to fragment program  ].join("\n");
            
            // v0:    input texCoords
            // v1:    map texCoords
            // fc0:   OneHalf
            // fc1-4: matrix
            
            var fragmentShader : String = [
                    "tex ft0,  v1, fs1 " + mapFlags,   // read map texture  
                    "sub ft1, ft0, fc0",   // subtract 0.5 -> range [-0.5, 0.5]  
                    "m44 ft2, ft1, fc1",   // multiply matrix with displacement values  
                    "add ft3,  v0, ft2",   // add displacement values to texture coords  
                    "tex  oc, ft3, fs0 " +inputFlags  // read input texture at displaced coords  ].join("\n");
            
            mShaderProgram = target.registerProgramFromSource(programName,
                            vertexShader, fragmentShader);
        }
    }
    
    /** @private */
    override private function activate(pass : Int, context : Context3D, texture : Texture) : Void
    {
        // already set by super class:
        //
        // vertex constants 0-3: mvpMatrix (3D)
        // vertex attribute 0:   vertex position (FLOAT_2)
        // vertex attribute 1:   texture coordinates (FLOAT_2)
        // texture 0:            input texture
        
        updateParameters(texture.nativeWidth, texture.nativeHeight);
        
        context.setVertexBufferAt(2, mMapTexCoordBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, sOneHalf);
        context.setProgramConstantsFromMatrix(Context3DProgramType.FRAGMENT, 1, sMatrix, true);
        context.setTextureAt(1, mMapTexture.base);
        context.setProgram(mShaderProgram);
    }
    
    /** @private */
    override private function deactivate(pass : Int, context : Context3D, texture : Texture) : Void
    {
        context.setVertexBufferAt(2, null);
        context.setTextureAt(1, null);
    }
    
    private function updateParameters(textureWidth : Int, textureHeight : Int) : Void
    {
        // matrix:
        // Maps RGBA values of map texture to UV-offsets in input texture.
        
        var scale : Float = Starling.contentScaleFactor;
        var columnX : Int;
        var columnY : Int;
        
        for (i in 0...16){sMatrixData[i] = 0;
        }
        
        if (mComponentX == BitmapDataChannel.RED)             columnX = 0
        else if (mComponentX == BitmapDataChannel.GREEN)             columnX = 1
        else if (mComponentX == BitmapDataChannel.BLUE)             columnX = 2
        else columnX = 3;
        
        if (mComponentY == BitmapDataChannel.RED)             columnY = 0
        else if (mComponentY == BitmapDataChannel.GREEN)             columnY = 1
        else if (mComponentY == BitmapDataChannel.BLUE)             columnY = 2
        else columnY = 3;
        
        sMatrixData[as3hx.Compat.parseInt(columnX * 4)] = mScaleX * scale / textureWidth;
        sMatrixData[as3hx.Compat.parseInt(columnY * 4 + 1)] = mScaleY * scale / textureHeight;
        
        sMatrix.copyRawDataFrom(sMatrixData);
        
        // vertex buffer: (containing map texture coordinates)
        // The size of input texture and map texture may be different. We need to calculate
        // the right values for the texture coordinates at the filter vertices.
        
        var mapX : Float = mMapPoint.x / mapTexture.nativeWidth;
        var mapY : Float = mMapPoint.y / mapTexture.nativeHeight;
        var maxU : Float = textureWidth / mapTexture.nativeWidth;
        var maxV : Float = textureHeight / mapTexture.nativeHeight;
        
        sMapTexCoords[0] = -mapX;sMapTexCoords[1] = -mapY;
        sMapTexCoords[2] = -mapX + maxU;sMapTexCoords[3] = -mapY;
        sMapTexCoords[4] = -mapX;sMapTexCoords[5] = -mapY + maxV;
        sMapTexCoords[6] = -mapX + maxU;sMapTexCoords[7] = -mapY + maxV;
        
        mMapTexture.adjustTexCoords(sMapTexCoords);
        mMapTexCoordBuffer.uploadFromVector(sMapTexCoords, 0, 4);
    }
    
    // properties
    
    /** Describes which color channel to use in the map image to displace the x result. 
     *  Possible values are constants from the BitmapDataChannel class. */
    private function get_ComponentX() : Int{return mComponentX;
    }
    private function set_ComponentX(value : Int) : Int{mComponentX = value;
        return value;
    }
    
    /** Describes which color channel to use in the map image to displace the y result. 
     *  Possible values are constants from the BitmapDataChannel class. */
    private function get_ComponentY() : Int{return mComponentY;
    }
    private function set_ComponentY(value : Int) : Int{mComponentY = value;
        return value;
    }
    
    /** The multiplier used to scale the x displacement result from the map calculation. */
    private function get_ScaleX() : Float{return mScaleX;
    }
    private function set_ScaleX(value : Float) : Float{mScaleX = value;
        return value;
    }
    
    /** The multiplier used to scale the y displacement result from the map calculation. */
    private function get_ScaleY() : Float{return mScaleY;
    }
    private function set_ScaleY(value : Float) : Float{mScaleY = value;
        return value;
    }
    
    /** The texture that will be used to calculate displacement. */
    private function get_MapTexture() : Texture{return mMapTexture;
    }
    private function set_MapTexture(value : Texture) : Texture
    {
        if (mMapTexture != value) 
        {
            mMapTexture = value;
            createPrograms();
        }
        return value;
    }
    
    /** A value that contains the offset of the upper-left corner of the target display 
     *  object from the upper-left corner of the map image. */
    private function get_MapPoint() : Point{return mMapPoint;
    }
    private function set_MapPoint(value : Point) : Point
    {
        if (value != null)             mMapPoint.setTo(value.x, value.y)
        else mMapPoint.setTo(0, 0);
        return value;
    }
    
    /** Indicates how the pixels at the edge of the input image (the filtered object) will
     *  be wrapped at the edge. */
    private function get_Repeat() : Bool{return mRepeat;
    }
    private function set_Repeat(value : Bool) : Bool
    {
        if (mRepeat != value) 
        {
            mRepeat = value;
            createPrograms();
        }
        return value;
    }
}
