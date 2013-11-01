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
		//var mStarling = new Starling(StarlingRoot, stage);
		//mStarling.enableErrorChecking = true;
		//mStarling.start();

		if (stage != null)
		rawStage3D();
		else
			addEventListener(Event.ADDED_TO_STAGE, rawStage3D);
	}

	private function rawStage3D(e:Event = null):Void
	{
		var stage3D = stage.getStage3D(0);
		stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		stage3D.requestContext3D("auto");
	}

	private function onContextCreated(event:Event):Void
	{
		var stage3D = cast(event.target, Stage3D);
		stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		context3D = stage3D.context3D;
		context3D.enableErrorChecking = true;
		context3D.setBlendFactors(flash.display3D.Context3DBlendFactor.SOURCE_ALPHA, flash.display3D.Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
		context3D.configureBackBuffer(500, 500, 2);


		var bitmapData = Assets.getBitmapData("assets/pirate.png");
		trace(bitmapData.width, bitmapData.height);
		var width = GetNextPowerOfTwo.getNextPowerOfTwo(bitmapData.width);
		var height = GetNextPowerOfTwo.getNextPowerOfTwo(bitmapData.height);
		trace(width, height);
		var bd = new BitmapData(width, height, true, 0x0);
		bd.copyPixels(bitmapData, bitmapData.rect, new Point(0,0));
		trace(bd.width, bd.height);

//bitmapData.perlinNoise(16,16, 8, 8, true, false);

		texture = context3D.createTexture(width, height, Context3DTextureFormat.BGRA, false);
		texture.uploadFromBitmapData(bd);

		var vertexData = Vector.ofArray([
			0.0, 0.0, 1, 1, 1, 1, 0, 0,
			1.0, 0.0, 1, 1, 1, 1, 1, 0,
			1.0, 1.0, 1, 1, 1, 1, 1, 1,
			0.0, 1.0, 1, 1, 1, 1, 0, 1
		]);
		vertexBuffer = context3D.createVertexBuffer(4, 8);
		vertexBuffer.uploadFromVector(vertexData, 0, 4);

		var positionData = Vector.ofArray([
			0.0, 0.0,
			1.0, 0.0,
			1.0, 1.0,
			0.0, 1.0
		]);

		var uvData = Vector.ofArray([
			0.0, 0,
			1.0, 0,
			1.0, 1,
			0.0, 1
		]);

		positionBuffer = context3D.createVertexBuffer(4, 2);
		positionBuffer.uploadFromVector(positionData, 0, 4);

		uvBuffer = context3D.createVertexBuffer(4, 2);
		uvBuffer.uploadFromVector(uvData, 0, 4);

		indexBuffer = context3D.createIndexBuffer(6);
		var indexData = new Vector<UInt>();
		indexData.push(0);
		indexData.push(1);
		indexData.push(2);
		indexData.push(0);
		indexData.push(2);
		indexData.push(3);

		indexBuffer.uploadFromVector(indexData, 0, indexData.length);

		var vertexShaderSource =
		"
			attribute vec2 vertexPosition;
		    attribute vec2 uv;
			uniform mat4 modelViewMatrix;
			varying vec2 vTexCoord;
			void main(void) {
				gl_Position = modelViewMatrix * vec4(vertexPosition.x, vertexPosition.y, 0, 1.0);
				vTexCoord = uv;
			}
			";

		var fragmentShaderSource =
		"
			varying vec2 vTexCoord;
			uniform sampler2D texture;
		    void main(void) {
		        gl_FragColor = texture2D(texture, vTexCoord);
			}
			";

		var vertexAgalInfo = '{
			"varnames":{"vertexPosition":"va0","uv":"va2","modelViewMatrix":"vc1"},
			"agalasm":"m44 op, va0, vc1\\nmov v1, va2","storage":{},
			"types":{},"info":"","consts":{}}';
		var fragmentAgalInfo = '{
			"varnames":{"texture":"fs0"},
			"agalasm":"tex  oc,  v1, fs0 <2d,linear,repeat,nearest>",
			"storage":{},"types":{},"info":"","consts":{}}';

		var vertextShader = new GLSLVertexShader(vertexShaderSource, vertexAgalInfo);
		var fragmentShader = new GLSLFragmentShader(fragmentShaderSource, fragmentAgalInfo);
		program = new GLSLProgram(context3D);
		program.upload(vertextShader, fragmentShader);

		context3D.setRenderCallback(onEnterFrame);
	}

	private function onEnterFrame(event:Event):Void
	{
		context3D.clear(0, 0, 0, 1);
		program.attach();


		program.setTextureAt("texture", texture);

		var matrix3D = new Matrix3D();
//matrix3D.appendTranslation(-250, -250, 0);
//matrix3D.appendScale(2.0/500, -2.0/500, 1);
		program.setVertexUniformFromMatrix("modelViewMatrix", matrix3D, true);

		program.setVertexBufferAt("vertexPosition", vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
		program.setVertexBufferAt("uv", vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_2);



		context3D.drawTriangles(indexBuffer, 0, 2);
		context3D.present();
	}

}