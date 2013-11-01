// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events;

import flash.geom.Point;

/** A ResizeEvent is dispatched by the stage when the size of the Flash container changes.
 *  Use it to update the Starling viewport and the stage size.
 *
 *  <p>The event contains properties containing the updated width and height of the Flash
 *  player. If you want to scale the contents of your stage to fill the screen, update the
 *  <code>Starling.current.viewPort</code> rectangle accordingly. If you want to make use of
 *  the additional screen estate, update the values of <code>stage.stageWidth</code> and
 *  <code>stage.stageHeight</code> as well.</p>
 *
 *  @see starling.display.Stage
 *  @see starling.core.Starling
 */
class ResizeEvent extends Event
{
	/** Event type for a resized Flash player. */
	public static inline var RESIZE:String = "resize";

	/** Creates a new ResizeEvent. */
	public function new(type:String, width:Float, height:Float, bubbles:Bool=false)
	{
		super(type, bubbles, new Point(width, height));
	}

	/** The updated width of the player. */
	public var width(get_width, null):Float;
	private function get_width():Float { return cast(data, Point).x; }

	/** The updated height of the player. */
	public var height(get_height, null):Float;
	private function get_height():Float { return cast(data, Point).y; }
}
