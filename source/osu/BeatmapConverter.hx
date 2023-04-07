package osu;

import base.ScriptableState;
import base.system.Conductor;
import funkin.ChartLoader.Song;
import funkin.ChartLoader;
import haxe.io.Path;
import states.BasicPlayState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

// Just converts the beatmaps into the standard FNF System
class BeatmapConverter
{
	private static var beatmap:Beatmap;
	private static var fnfChart:Song = {
		song: "parsed_beatmap",
		stage: "stage",
		speed: 3,
		needsVoices: false,
		bpm: 250,
		notes: []
	};

	public static function convertBeatmap(filePath:String)
	{
		var parentDir:String = Path.join([Path.withoutExtension(filePath)]);
		var audioDir:String = Path.join([parentDir, "audio.ogg"]);
		var map:Array<String> = File.getContent(filePath).split("\n");
		beatmap = new Beatmap(map);

		trace('${map.length - (beatmap.find("[HitObjects]") + 1)} notes');

		beatmap.Artist = beatmap.getOption('Artist');
		beatmap.ArtistUnicode = beatmap.getOption("ArtistUnicode");

		beatmap.Title = beatmap.getOption("Title");
		beatmap.TitleUnicode = beatmap.getOption("TitleUnicode");

		var bpm:Float = 0;
		var bpmCount:Float = 0;

		for (i in beatmap.find('[TimingPoints]')...(beatmap.find('[HitObjects]') - 2))
		{
			if (map[i].split(",")[6] == "1")
			{
				bpm = bpm + Std.parseFloat(map[i].split(",")[1]);
				bpmCount++;
			}
			beatmap.BPM = bpm / bpmCount;
		}

		Conductor.changeBPM(beatmap.BPM);
		fnfChart.bpm = beatmap.BPM;
		if (FileSystem.exists(audioDir))
			Cache.getSound(audioDir, true);

		trace("parse notes");

		var i1 = beatmap.find('[HitObjects]') + 1;
		var toData:Dynamic = [];
		var what:Int = 0;

		while (i1 < map.length)
		{
			if (i1 == map.length - 1)
				break;

			i1++;

			toData[what] = [
				Std.parseInt(beatmap.line(map[i1], 2, ',')),
				convertNote(beatmap.line(map[i1], 0, ',')),
				Std.parseFloat(beatmap.line(map[i1], 5, ',')) - Std.parseFloat(beatmap.line(map[i1], 2, ','))
			];

			if (toData[what][2] < 0)
				toData[what][2] = 0;

			what++;
		}

		trace("placing notes");

		var i2 = 0;
		var sectionNote:Int = 0;
		var curSection:Int = 0;
		while (i2 < toData.length)
		{
			fnfChart.notes[curSection] = {
				sectionNotes: [],
				sectionBeats: null,
				mustHitSection: true,
				lengthInSteps: 16,
				changeBPM: false,
				bpm: fnfChart.bpm
			};

			for (note in 0...toData.length)
			{
				if (toData[note][0] <= ((curSection + 1) * (4 * (1000 * 60 / fnfChart.bpm)))
					&& toData[note][0] > ((curSection) * (4 * (1000 * 60 / fnfChart.bpm))))
				{
					fnfChart.notes[curSection].sectionNotes[sectionNote] = toData[note];
					sectionNote++;
				}
			}
			sectionNote = 0;

			if (toData[Std.int(toData.length - 1)] == fnfChart.notes[curSection].sectionNotes[fnfChart.notes[curSection].sectionNotes.length - 1])
				break;

			curSection++;
			i2++;
		}

		trace("parsing fnf chart");

		ChartLoader.loadSong(fnfChart);

		trace("done parsing");
		Conductor.bindSong(Cache.getSound(audioDir, true), fnfChart.bpm);
		Conductor.songData = fnfChart;
		ScriptableState.switchState(new BasicPlayState());
	}

	private static function numberArray(?min = 0, max:Int):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	static function convertNote(from_note:Dynamic)
	{
		from_note = Std.parseInt(from_note);
		var noteArray = [
			numberArray(0, 127), numberArray(128, 255), numberArray(256, 383), numberArray(384, 511),
			numberArray(0, 127), numberArray(128, 255), numberArray(256, 383), numberArray(384, 511)
		];

		for (i in 0...noteArray.length)
		{
			for (i2 in 0...noteArray[i].length)
			{
				if (noteArray[i][i2] == from_note)
				{
					trace('Found note');
					return i;
				}
			}
		}

		trace("Couldn't find note " + from_note + ' in note array');
		return 0;
	}
}
