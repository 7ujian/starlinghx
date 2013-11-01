// =================================================================================================
//
// Starling Framework
// Copyright 2011 Gamua OG. All Rights Reserved.
//
// This program is free software. You can redistribute and/or modify it
// in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================
package starling.display;

import flash.errors.ArgumentError;
import flash.errors.IllegalOperationError;
import flash.media.Sound;

import starling.animation.IAnimatable;
import starling.events.Event;
import starling.textures.Texture;

/** Dispatched whenever the movie has displayed its last frame. */
@:meta(Event(name="complete", type="starling.events.Event"))
/** A MovieClip is a simple way to display an animation depicted by a list of textures.
 *
 *  <p>Pass the frames of the movie in a vector of textures to the constructor. The movie clip
 *  will have the width and height of the first frame. If you group your frames with the help
 *  of a texture atlas (which is recommended), use the <code>getTextures</code>-method of the
 *  atlas to receive the textures in the correct (alphabetic) order.</p>
 *
 *  <p>You can specify the desired framerate via the constructor. You can, however, manually
 *  give each frame a custom duration. You can also play a sound whenever a certain frame
 *  appears.</p>
 *
 *  <p>The methods <code>play</code> and <code>pause</code> control playback of the movie. You
 *  will receive an event of type <code>Event.MovieCompleted</code> when the movie finished
 *  playback. If the movie is looping, the event is dispatched once per loop.</p>
 *
 *  <p>As any animated object, a movie clip has to be added to a juggler (or have its
 *  <code>advanceTime</code> method called regularly) to run. The movie will dispatch
 *  an event of type "Event.COMPLETE" whenever it has displayed its last frame.</p>
 *
 *  @see starling.textures.TextureAtlas
 */
class MovieClip extends Image implements IAnimatable
{
	private var mTextures : Array<Texture>;
	private var mNumFrames: Int = 0;
	private var mSounds : Array<Sound>;
	private var mDurations : Array<Float>;
	private var mStartTimes : Array<Float>;
	private var mDefaultFrameDuration :Float;
	private var mCurrentTime :Float;
	private var mCurrentFrame :Int;
	private var mLoop :Bool;
	private var mPlaying :Bool;

	/** Creates a movie clip from the provided textures and with the specified default framerate.
	 *  The movie will have the size of the first frame. */
	public function new(textures : Array<Texture>, fps :Float = 12)
	{
		if (textures.length > 0)
		{
			super(textures[0]);
			init(textures, fps);
		}
		else
		{
			throw new ArgumentError("Empty texture array");
		}
	}

	private function init(textures : Array<Texture>, fps :Float, currentTime:Float = 0) :Void
	{
		if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
		var numFrames :Int = textures.length;

		mDefaultFrameDuration = 1.0 / fps;
		mLoop = true;
		mPlaying = true;
		mCurrentTime = 0.0;
		mCurrentFrame = 0;
		mTextures = textures.concat([]);
		mNumFrames = mTextures.length;
		mSounds = new Array<Sound>();
		mDurations = new Array<Float>();
		mStartTimes = new Array<Float>();

		for (i in 0...numFrames)
		{
			mDurations[i] = mDefaultFrameDuration;
			mStartTimes[i] = i * mDefaultFrameDuration;
		}
	}

	public function swapTextures(textures : Array<Texture>, fps :Float = 12) :Void
	{
		//init(textures, fps);
		mTextures = textures.concat([]);
		mNumFrames = mTextures.length;
		readjustSize();
//			stop();
	}

	// frame manipulation
	/** Adds an additional frame, optionally with a sound and a custom duration. If the
	 *  duration is omitted, the default framerate is used (as specified in the constructor). */
	public function addFrame(texture : Texture, sound : Sound = null, duration :Float = -1) :Void
	{
		addFrameAt(numFrames, texture, sound, duration);
	}

	/** Adds a frame at a certain index, optionally with a sound and a custom duration. */
	public function addFrameAt(frameID :Int, texture : Texture, sound : Sound = null, duration :Float = -1) :Void
	{
		if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
		if (duration < 0) duration = mDefaultFrameDuration;

		mTextures.insert(frameID, texture);
		mNumFrames = mTextures.length;
		mSounds.insert(frameID, sound);
		mDurations.insert(frameID, duration);

		if (frameID > 0 && frameID == numFrames)
			mStartTimes[frameID] = mStartTimes[frameID - 1] + mDurations[frameID - 1];
		else
			updateStartTimes();
	}

	/** Removes the frame at a certain ID. The successors will move down. */
	public function removeFrameAt(frameID :Int) :Void
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");

		mTextures.splice(frameID, 1);
		mNumFrames = mTextures.length;
		mSounds.splice(frameID, 1);
		mDurations.splice(frameID, 1);

		updateStartTimes();
	}

	/** Returns the texture of a certain frame. */
	public function getFrameTexture(frameID :Int) : Texture
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		return mTextures[frameID];
	}

	/** Sets the texture of a certain frame. */
	public function setFrameTexture(frameID :Int, texture : Texture) :Void
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		mTextures[frameID] = texture;
	}

	/** Returns the sound of a certain frame. */
	public function getFrameSound(frameID :Int) : Sound
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		return mSounds[frameID];
	}

	/** Sets the sound of a certain frame. The sound will be played whenever the frame
	 *  is displayed. */
	public function setFrameSound(frameID :Int, sound : Sound) :Void
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		mSounds[frameID] = sound;
	}

	/** Returns the duration of a certain frame (in seconds). */
	public function getFrameDuration(frameID :Int) :Float
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		return mDurations[frameID];
	}

	/** Sets the duration of a certain frame (in seconds). */
	public function setFrameDuration(frameID :Int, duration :Float) :Void
	{
		if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
		mDurations[frameID] = duration;
		updateStartTimes();
	}

	// playback methods
	/** Starts playback. Beware that the clip has to be added to a juggler, too! */
	public function play() :Void
	{
		mPlaying = true;
	}

	/** Pauses playback. */
	public function pause() :Void
	{
		mPlaying = false;
	}

	/** Stops playback, resetting "currentFrame" to zero. */
	public function stop() :Void
	{
		mPlaying = false;
		currentFrame = 0;
	}

	// helpers
	private function updateStartTimes() :Void
	{
		var numFrames :Int = this.numFrames;

		//mStartTimes.length = 0;
		mStartTimes[0] = 0;

		for (i in 1...numFrames)
			mStartTimes[i] = mStartTimes[i - 1] + mDurations[i - 1];
	}

	// IAnimatable
	/** @inheritDoc */
	public function advanceTime(passedTime :Float) :Void
	{
		if (!mPlaying || passedTime <= 0.0) return;

		var finalFrame :Int;
		var previousFrame :Int = mCurrentFrame;
		var restTime :Float = 0.0;
		var breakAfterFrame :Bool = false;
		var hasCompleteListener :Bool = false;
		var hasCompleteListenerValid:Bool = false;

		var dispatchCompleteEvent :Bool = false;
		var totalTime :Float = this.totalTime;

		if (mLoop && mCurrentTime >= totalTime)
		{
			mCurrentTime = 0.0;
			mCurrentFrame = 0;
		}

		if (mCurrentTime < totalTime)
		{
			mCurrentTime += passedTime;
			finalFrame = mTextures.length - 1;

			while (mCurrentTime > mStartTimes[mCurrentFrame] + mDurations[mCurrentFrame])
			{
				if (mCurrentFrame == finalFrame)
				{
					if (!hasCompleteListenerValid)
					{
						hasCompleteListenerValid = true;
						hasCompleteListener = hasEventListener(Event.COMPLETE);
					}

					if (mLoop && !hasCompleteListener)
					{
						mCurrentTime -= totalTime;
						mCurrentFrame = 0;
					}
					else
					{
						breakAfterFrame = true;
						restTime = mCurrentTime - totalTime;
						dispatchCompleteEvent = hasCompleteListener;
						mCurrentFrame = finalFrame;
						mCurrentTime = totalTime;
					}
				}
				else
				{
					mCurrentFrame++;
				}

				var sound : Sound = mSounds[mCurrentFrame];
				if (sound != null) sound.play();
				if (breakAfterFrame) break;
			}

			// special case when we reach *exactly* the total time.
			if (mCurrentFrame == finalFrame && mCurrentTime == totalTime)
			{
				if (!hasCompleteListenerValid)
				{
					hasCompleteListenerValid = true;
					hasCompleteListener = hasEventListener(Event.COMPLETE);
				}

			}
				dispatchCompleteEvent = hasCompleteListener;
		}

		if (mCurrentFrame != previousFrame)
			texture = mTextures[mCurrentFrame];

		if (dispatchCompleteEvent)
			dispatchEventWith(Event.COMPLETE);

		if (mLoop && restTime > 0.0)
			advanceTime(restTime);
	}

	/** Indicates if a (non-looping) movie has come to its end. */
	public var isComplete(get_isComplete, null):Bool;
	private inline function get_isComplete() :Bool
	{
		return !mLoop && mCurrentTime >= totalTime;
	}

	// properties
	/** The total duration of the clip in seconds. */
	public var totalTime(get_totalTime, null):Float;
	private inline function get_totalTime() :Float
	{
		return mStartTimes[mNumFrames - 1] + mDurations[mNumFrames - 1];
	}

	/** The time that has passed since the clip was started (each loop starts at zero). */
	public var currentTime(get_currentTime, null):Float;
	private inline function get_currentTime() :Float
	{
		return mCurrentTime;
	}

	/** The total number of frames. */
	public var numFrames(get_numFrames, null):Int;
	private inline function get_numFrames() :Int
	{
		return mNumFrames;
	}

	/** Indicates if the clip should loop. */
	public var loop(get_loop, set_loop):Bool;
	private inline function get_loop() :Bool
	{
		return mLoop;
	}

	private inline function set_loop(value :Bool) :Bool
	{
		return mLoop = value;
	}

	/** The index of the frame that is currently displayed. */
	public var currentFrame(get_currentFrame, set_currentFrame):Int;
	private inline function get_currentFrame() :Int
	{
		return mCurrentFrame;
	}

	private function set_currentFrame(value :Int) :Int
	{
		mCurrentFrame = value;
		mCurrentTime = 0.0;

		for (i in 0...value)
			mCurrentTime += getFrameDuration(i);

		texture = mTextures[mCurrentFrame];
		if (mSounds[mCurrentFrame] != null) mSounds[mCurrentFrame].play();

		return value;
	}

	/** The default number of frames per second. Individual frames can have different
	 *  durations. If you change the fps, the durations of all frames will be scaled
	 *  relatively to the previous value. */
	public var fps(get_fps, set_fps):Float;
	private inline function get_fps() :Float
	{
		return 1.0 / mDefaultFrameDuration;
	}

	private function set_fps(value :Float) :Float
	{
		if (value <= 0) throw new ArgumentError("Invalid fps: " + value);

		var newFrameDuration :Float = 1.0 / value;
		var acceleration :Float = newFrameDuration / mDefaultFrameDuration;
		mCurrentTime *= acceleration;
		mDefaultFrameDuration = newFrameDuration;

		for (i in 0...numFrames)
		{
			var duration :Float = mDurations[i] * acceleration;
			mDurations[i] = duration;
		}

		updateStartTimes();

		return value;
	}

	/** Indicates if the clip is still playing. Returns <code>false</code> when the end
	 *  is reached. */
	public var isPlaying(get_isPlaying, null):Bool;
	private function get_isPlaying() :Bool
	{
		if (mPlaying)
			return mLoop || mCurrentTime < totalTime;
		else
			return false;
	}
}
