package;

import Xml;
import starling.core.Starling;
import starling.display.MovieClip;
import starling.textures.TextureAtlas;
import openfl.Assets;
import starling.display.Image;
import starling.textures.Texture;
import flash.display.BitmapData;
import starling.display.Sprite;

class StarlingRoot extends Sprite
{
	public function new ()
	{
		super();
		var bitmapData:BitmapData = Assets.getBitmapData("assets/pirate.png");
		//bitmapData.perlinNoise(16,16, 8, 8, true, false);

		var texture = Texture.fromBitmapData(bitmapData);
		var image = new Image(texture);

		addChild(image);

		var atlasPNG = Assets.getBitmapData("assets/atlas.png");
		var atlasXML = Assets.getText("assets/atlas.xml");

		var texture = Texture.fromBitmapData(atlasPNG);
		var atlas = new TextureAtlas(texture, Xml.parse(atlasXML));
		var textures = atlas.getTextures("flight_");

		var currentTime:Float = 0;
		for (i in 0...20)
		{
			for (j in 0...10)
			{
			var mc = new MovieClip(textures, 60);
			mc.x = i * 5;
			mc.y = j * 5 - 50;
			mc.play();
			Starling.sJuggler.add(mc);
			addChild(mc);
			}
		}

		//var bitmap = new Bitmap(bitmapData);
		//Starling.current.nativeStage.addChild(bitmap);
	}
}
