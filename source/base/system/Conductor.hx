package base.system;

import base.MusicBeatState.MusicHandler;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.ChartLoader;
import funkin.notes.Note;
import openfl.media.Sound;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	// song shit
	public static var songPosition:Float = 0;
	public static var songSpeed(default, set):Float = 2;
	public static var songRate:Float = 0.45;

	// steps and beats
	public static var stepPosition:Int = 0;
	public static var beatPosition:Int = 0;

	// for resync??
	public static final comparisonThreshold:Float = 30;
	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	// bpm shit
	public static var bpm:Float = 0;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	// the audio shit and the signals
	public static var boundSong:FlxSound;
	public static var songData:Song;
	public static var onStepHit:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public static var onBeatHit:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	// note stuff
	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000);
	public static var timeScale:Float = safeZoneOffset / 166;

	public function new() {}

	public static function bindSong(newSong:Sound, bpm:Float)
	{
		boundSong = new FlxSound().loadEmbedded(newSong);

		FlxG.sound.list.add(boundSong);

		changeBPM(bpm);

		reset();
	}

	private static function set_songSpeed(value:Float):Float
	{
		var ratio:Float = value / songSpeed;
		songSpeed = value;
		for (note in ChartLoader.unspawnedNoteList)
		{
			note.updateSustainScale(ratio);
		}
		return value;
	}

	public static function changeBPM(newBPM:Float)
	{
		bpm = newBPM;

		crochet = calculateCrochet(newBPM);
		stepCrochet = (crochet / 4);

		if (songData != null)
		{
			// Thanks Kade for the comment about xmod on Psych Engine, you are the best
			// this probably is the best way, it keeps the original song speed but when a bpm speed changes it slows down, (135 -> 145) it slows the song a lot
			var baseSpeed:Float = songRate * songData.speed;
			var bps:Float = (bpm / 60) / songRate;

			var nearestNote:Note = ChartLoader.unspawnedNoteList[0];
			var noteDiff:Float = (nearestNote.strumTime - songPosition) / 1000;

			songSpeed = baseSpeed / (bps * noteDiff);
		}
	}

	public static function updateTimePosition(elapsed:Float)
	{
		if (FlxG.sound.music.playing)
		{
			stepPosition = Math.floor(songPosition / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				onStepHit.dispatch();
				lastStep = stepPosition;
			}

			if (beatPosition > lastBeat)
			{
				if (stepPosition % 4 == 0)
					onBeatHit.dispatch();
				lastBeat = beatPosition;
			}

			songPosition += elapsed * 1000;
		}

		if (boundSong != null && boundSong.playing)
		{
			var lastChange:BPMChangeEvent = getBPMFromSeconds(songPosition);

			stepPosition = lastChange.stepTime + Math.floor((songPosition - lastChange.songTime) / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				if (Math.abs(boundSong.time - songPosition) > comparisonThreshold)
					resyncTime();

				onStepHit.dispatch();
				lastStep = stepPosition;
			}

			if (beatPosition > lastBeat)
			{
				if (stepPosition % 4 == 0)
					onBeatHit.dispatch();
				lastBeat = beatPosition;
			}

			songPosition += elapsed * 1000;
		}
	}

	public static function resyncTime()
	{
		trace('Resyncing song time ${boundSong.time}, $songPosition');

		boundSong.play();
		songPosition = boundSong.time;
		trace('New song time ${boundSong.time}, $songPosition');
	}

	public static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
	}

	public static inline function calculateCrochet(bpm:Float)
		return (60 / bpm) * 1000;

	public static function reset()
	{
		songPosition = 0;
		stepPosition = 0;
		beatPosition = 0;
		lastStep = -1;
		lastBeat = -1;
	}
}
