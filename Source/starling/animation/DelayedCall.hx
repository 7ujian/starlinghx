// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.animation;

import starling.events.Event;
import starling.events.EventDispatcher;

/** A DelayedCall allows you to execute a method after a certain time has passed. Since it
 *  implements the IAnimatable interface, it can be added to a juggler. In most cases, you
 *  do not have to use this class directly; the juggler class contains a method to delay
 *  calls directly.
 *
 *  <p>DelayedCall dispatches an Event of type 'Event.REMOVE_FROM_JUGGLER' when it is finished,
 *  so that the juggler automatically removes it when its no longer needed.</p>
 *
 *  @see Juggler
 */
class DelayedCall extends EventDispatcher implements IAnimatable
{
	private var mCurrentTime:Float;
	private var mTotalTime:Float;
	private var mCall:Array<Dynamic>->Void;
	private var mArgs:Array<Dynamic>;
	private var mRepeatCount:Int;

	/** Creates a delayed call. */
	public function new(call:Array<Dynamic>->Void, delay:Float, args:Array<Dynamic> =null)
	{
		reset(call, delay, args);
	}

	/** Resets the delayed call to its default values, which is useful for pooling. */
	public function reset(call:Array<Dynamic>->Void, delay:Float, args:Array<Dynamic> =null):DelayedCall
	{
		mCurrentTime = 0;
		mTotalTime = Math.max(delay, 0.0001);
		mCall = call;
		mArgs = args;
		mRepeatCount = 1;

		return this;
	}

	/** @inheritDoc */
	public function advanceTime(time:Float):Void
	{
		var previousTime:Float = mCurrentTime;
		mCurrentTime = Math.min(mTotalTime, mCurrentTime + time);

		if (previousTime < mTotalTime && mCurrentTime >= mTotalTime)
		{
			mCall(mArgs);

			if (mRepeatCount == 0 || mRepeatCount > 1)
			{
				if (mRepeatCount > 0) mRepeatCount -= 1;
				mCurrentTime = 0;
				advanceTime((previousTime + time) - mTotalTime);
			}
			else
			{
				dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
			}
		}
	}

	/** Indicates if enough time has passed, and the call has already been executed. */
	public var isComplete(get_isComplete, null):Bool;
	private function get_isComplete():Bool
	{
		return mRepeatCount == 1 && mCurrentTime >= mTotalTime;
	}

	/** The time for which calls will be delayed (in seconds). */
	public var totalTime(get_totalTime, null):Float;
	private function get_totalTime():Float { return mTotalTime; }

	/** The time that has already passed (in seconds). */
	public var currentTime(get_currentTime, null):Float;
	private function get_currentTime():Float { return mCurrentTime; }

	/** The number of times the call will be repeated.
	 *  Set to '0' to repeat indefinitely. @default 1 */
	public var repeatCount(get_repeatCount, set_repeatCount):Int;
	private function get_repeatCount():Int { return mRepeatCount; }
	private function set_repeatCount(value:Int):Int {return mRepeatCount = value; }
}
