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

import flash.Vector;
import starling.display.DisplayObject;
import haxe.ds.StringMap;



/** The EventDispatcher class is the base class for all classes that dispatch events.
 *  This is the Starling version of the Flash class with the same name.
 *
 *  <p>The event mechanism is a key feature of Starling's architecture. Objects can communicate
 *  with each other through events. Compared the the Flash event system, Starling's event system
 *  was simplified. The main difference is that Starling events have no "Capture" phase.
 *  They are simply dispatched at the target and may optionally bubble up. They cannot move
 *  in the opposite direction.</p>
 *
 *  <p>As in the conventional Flash classes, display objects inherit from EventDispatcher
 *  and can thus dispatch events. Beware, though, that the Starling event classes are
 *  <em>not compatible with Flash events:</em> Starling display objects dispatch
 *  Starling events, which will bubble along Starling display objects - but they cannot
 *  dispatch Flash events or bubble along Flash display objects.</p>
 *
 *  @see Event
 *  @see starling.display.DisplayObject DisplayObject
 */
class EventDispatcher
{
	private var mEventListeners:StringMap<Vector<Dynamic->Void>>;

	/** Helper object. */
	private static var sBubbleChains:Vector<Vector<EventDispatcher>> = new Vector<Vector<EventDispatcher>>();

	/** Creates an EventDispatcher. */
	public function EventDispatcher()
	{  }

	/** Registers an event listener at a certain object. */
	public function addEventListener(type:String, listener:Dynamic->Void):Void
	{
		if (mEventListeners == null)
			mEventListeners = new StringMap<Vector<Dynamic->Void>>();

		var listeners:Vector<Dynamic->Void> = mEventListeners.get(type);
		if (listeners == null)
		{
			listeners = new Vector<Dynamic->Void>();
			listeners.push(listener);
			mEventListeners.set(type, listeners);
		}
		else if (listeners.indexOf(listener) == -1) // check for duplicates
			listeners.push(listener);
	}

	/** Removes an event listener from the object. */
	public function removeEventListener(type:String, listener:Dynamic->Void):Void
	{
		if (mEventListeners!=null)
		{
			var listeners:Vector<Dynamic->Void> = mEventListeners.get(type);
			if (listeners!=null)
			{
				var numListeners = listeners.length;
				var remainingListeners = new Vector<Dynamic->Void>();

				for (i in 0...numListeners)
				{
					var otherListener = listeners[i];
					if (otherListener != listener) remainingListeners.push(otherListener);
				}

				mEventListeners.set(type, remainingListeners);
			}
		}
	}

	/** Removes all event listeners with a certain type, or all of them if type is null.
	 *  Be careful when removing all event listeners: you never know who else was listening. */
	public function removeEventListeners(type:String=null):Void
	{
		if (type != null && mEventListeners != null)
			mEventListeners.remove(type);
		else
			mEventListeners = null;
	}

	/** Dispatches an event to all objects that have registered listeners for its type.
	 *  If an event with enabled 'bubble' property is dispatched to a display object, it will
	 *  travel up along the line of parents, until it either hits the root object or someone
	 *  stops its propagation manually. */
	public function dispatchEvent(event:Event):Void
	{
		var bubbles = event.bubbles;

		if (!bubbles && (mEventListeners == null || !mEventListeners.exists(event.type)))
			return; // no need to do anything

		// we save the current target and restore it later;
		// this allows users to re-dispatch events without creating a clone.

		var previousTarget:EventDispatcher = event.target;
		event.setTarget(this);

		if (bubbles && Std.is(this, DisplayObject)) bubbleEvent(event);
		else                                  invokeEvent(event);

		if (previousTarget!=null) event.setTarget(previousTarget);
	}

	/** @private
	 *  Invokes an event on the current object. This method does not do any bubbling, nor
	 *  does it back-up and restore the previous target on the event. The 'dispatchEvent'
	 *  method uses this method internally. */
	@:allow(starling.events) function invokeEvent(event:Event):Bool
	{
		var listeners:Vector<Dynamic->Void> = mEventListeners !=null ?
			mEventListeners.get(event.type) : null;
		var numListeners:Int = listeners == null ? 0 : listeners.length;

		if (numListeners>0)
		{
			event.setCurrentTarget(this);

			// we can enumerate directly over the vector, because:
			// when somebody modifies the list while we're looping, "addEventListener" is not
			// problematic, and "removeEventListener" will create a new Vector, anyway.

			for (i in 0...numListeners)
			{
				var listener = listeners[i];
				listener(event);

				if (event.stopsImmediatePropagation)
					return true;
			}

			return event.stopsPropagation;
		}
		else
		{
			return false;
		}
	}

	/** @private */
	@:allow(starling.events) function bubbleEvent(event:Event):Void
	{
		// we determine the bubble chain before starting to invoke the listeners.
		// that way, changes done by the listeners won't affect the bubble chain.

		var chain:Vector<EventDispatcher>;
		var element:DisplayObject = cast this;
		var length = 1;

		if (sBubbleChains.length > 0) { chain = sBubbleChains.pop(); chain[0] = element; }
		else
		{
			chain = new Vector<EventDispatcher>();
			chain.push(element);
		}

		while ((element = element.parent) != null)
			chain[length++] = element;

		for (i in 0...length)
		{
			var stopPropagation:Bool = chain[i].invokeEvent(event);
			if (stopPropagation) break;
		}

		chain.length = 0;
		sBubbleChains.push(chain);
	}

	/** Dispatches an event with the given parameters to all objects that have registered
	 *  listeners for the given type. The method uses an internal pool of event objects to
	 *  avoid allocations. */
	public function dispatchEventWith(type:String, bubbles:Bool=false, data:Dynamic=null):Void
	{
		if (bubbles || hasEventListener(type))
		{
			var event:Event = Event.fromPool(type, bubbles, data);
			dispatchEvent(event);
			Event.toPool(event);
		}
	}

	/** Returns if there are listeners registered for a certain event type. */
	public function hasEventListener(type:String):Bool
	{
		if (mEventListeners == null) return false;

		if (!mEventListeners.exists(type)) return false;

		var listeners:Vector<Dynamic->Void> = mEventListeners.get(type);
		if (listeners == null || listeners.length == 0) return false;

		return true;
	}
}
