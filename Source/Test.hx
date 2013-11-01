package;

import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.IndexBuffer3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.Vector;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DRenderMode;
import flash.geom.Matrix3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.Vector;
import flash.display3D.shaders.glsl.GLSLFragmentShader;
import flash.display3D.shaders.glsl.GLSLVertexShader;
import flash.display3D.shaders.glsl.GLSLProgram;
import flash.display3D.Context3DTextureFormat;
import flash.geom.Point;
import flash.display.BitmapData;
import openfl.Assets;
import starling.utils.GetNextPowerOfTwo;
import flash.display.Stage3D;
import flash.events.Event;
import flash.events.EventDispatcher;
import starling.core.Starling;
import flash.display.Sprite;

using OpenFLStage3D;
using Stage3DHelper;

class Test extends Sprite
{
	private var program:GLSLProgram;
	private var texture:Texture;
	private var vertexBuffer:VertexBuffer3D;
	private var indexBuffer:IndexBuffer3D;
	private var positionBuffer:VertexBuffer3D;
	private var uvBuffer:VertexBuffer3D;
	private var context3D:Context3D;

	public function new()
	{
		super();


		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(e:Event = null):Void
	{
		stage.frameRate = 60;

		var mStarling = new Starling(StarlingRoot, stage);
		mStarling.enableErrorChecking = false;
		mStarling.showStats = true;
		mStarling.start();
	}



}