package base.system;

import flixel.FlxG;
import flixel.system.FlxSound;
import funkin.ChartLoader;
import funkin.CoolUtil;
import haxe.Exception;
import haxe.io.Path;
import lime.app.Application;
import lime.system.System;
import openfl.media.Sound;
import osu.BeatmapConverter;
import states.BasicPlayState;
import sys.FileSystem;
import sys.io.File;

using StringTools;

// Save it on the song store
class DragDrop
{
	public static function listen()
	{
		Application.current.window.onDropFile.add((filePath:String) ->
		{
			var fileExtension:String = Path.extension(filePath);
			var fileName:String = Path.withoutDirectory(Path.withoutExtension(filePath));

			trace([fileName, fileExtension]);

			switch (fileExtension)
			{
				case "osz":
					{
						var extractDirectory:String = Path.join([System.applicationStorageDirectory, fileName]);

						if (!FileSystem.exists(extractDirectory))
							FileSystem.createDirectory(extractDirectory);

						var execPath:String = Path.join([Sys.getCwd(), "7z", "7z.exe"]);
						var soundPath:String = Path.join([extractDirectory, "audio.mp3"]);
						if (Sys.command('$execPath e "$filePath" -o"$extractDirectory" -y -r') == 0)
						{
							if (FileSystem.exists(soundPath))
								convertFile(soundPath);
						}
					}

				case "osu":
					{
						BeatmapConverter.convertBeatmap(filePath);
					}

				case "json":
					{
						var parentDir:String = Path.join([Path.directory(filePath)]);

						var coolSwag:Song = CoolUtil.loadSong(File.getContent(filePath));
						var soundDir:String = Path.join([parentDir, "Inst.ogg"]);

						if (!FileSystem.exists(soundDir))
							throw new Exception("Sound file not found on " + parentDir);

						var sound:Sound = Sound.fromFile(soundDir);

						coolSwag = ChartLoader.loadSong(coolSwag);
						Conductor.bindSong(sound, coolSwag.bpm);
						Conductor.songData = coolSwag;
						ScriptableState.switchState(new BasicPlayState());
					}
			}
		});
	}

	public static function convertFile(path:String)
	{
		var ffmpegPath:String = Path.join([Sys.getCwd(), "FFmpeg", "ffmpeg.exe"]);
		var output:String = Path.withoutExtension(path) + ".ogg";
		if (Sys.command('$ffmpegPath -i "$path" -c:a libvorbis -q:a 4 "$output" -y') == 0)
			FileSystem.deleteFile(path);
	}
}
