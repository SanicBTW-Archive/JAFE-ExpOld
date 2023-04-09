package funkin;

import base.MusicBeatState.MusicHandler;
import base.system.Conductor;
import flixel.util.FlxSort;
import funkin.CoolUtil;
import funkin.notes.Note;
import openfl.Assets;
import openfl.media.Sound;

using StringTools;

typedef Section =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Null<Int>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
}

typedef Song =
{
	var song:String;
	var notes:Array<Section>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var stage:String;
}

class ChartLoader
{
	public static var unspawnedNoteList:Array<Note> = [];

	public static function loadChart(state:MusicHandler, songName:String, type:String):Song
	{
		Conductor.bpmChangeMap = [];
		unspawnedNoteList = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		var swagSong:Song = null;
		parseNotes(swagSong);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	public static function loadSong(raw:Song)
	{
		Conductor.bpmChangeMap = [];
		unspawnedNoteList = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		parseNotes(raw);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return raw;
	}

	public static function parseNotes(swagSong:Song)
	{
		var curBPM:Float = swagSong.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (section in swagSong.notes)
		{
			if (section.changeBPM && section.bpm != curBPM)
			{
				curBPM = section.bpm;
				var bpmChange:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: (Conductor.calculateCrochet(curBPM) / 4)
				};
				Conductor.bpmChangeMap.push(bpmChange);
			}

			var deltaSteps:Int = (section.sectionBeats != null ? Math.round(section.sectionBeats) * 4 : section.lengthInSteps);
			totalSteps += deltaSteps;
			totalPos += (Conductor.calculateCrochet(curBPM) / 4) * deltaSteps;

			for (songNotes in section.sectionNotes)
			{
				switch (songNotes[1])
				{
					default:
						// trace("Am i fucking parsing notes or soemthing");
						var strumTime:Float = songNotes[0];
						var noteData:Int = Std.int(songNotes[1] % 4);
						var hitNote:Bool = section.mustHitSection;

						if (songNotes[1] > 3)
							hitNote = !section.mustHitSection;

						var strumLine:Int = (hitNote ? 1 : 0);
						var holdStep:Float = (songNotes[2] / Conductor.stepCrochet);

						var newNote:Note = new Note(strumTime, noteData, strumLine);
						newNote.mustPress = hitNote;
						unspawnedNoteList.push(newNote);

						if (holdStep > 0)
						{
							var floorStep:Int = Std.int(holdStep + 1);
							for (i in 0...floorStep)
							{
								var sustainNote:Note = new Note(strumTime + (Conductor.stepCrochet * (i + 1)), noteData, strumLine,
									unspawnedNoteList[Std.int(unspawnedNoteList.length - 1)], true);
								sustainNote.mustPress = hitNote;
								sustainNote.parent = newNote;
								newNote.children.push(sustainNote);
								if (i == floorStep - 1)
									sustainNote.isSustainEnd = true;
								unspawnedNoteList.push(sustainNote);
							}
						}
				}
			}
		}

		unspawnedNoteList.sort(sortByShit);
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
}
