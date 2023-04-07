package base.system;

import flixel.FlxG;
import flixel.util.FlxSave;
import funkin.ChartLoader.Song;
import funkin.ChartLoader;
import lime.app.Application;
import openfl.media.Sound;

using StringTools;

#if !html5
import haxe.io.Bytes;
import haxe.io.Path;
import lime.system.System;
#end

class SaveFile
{
	private static var _save(default, null):FlxSave;
	private static var _songStore(default, null):SqliteKeyValue;

	public static var bound:Bool = false;

	public static function Initialize()
	{
		#if !debug
		FlxG.save.close();
		#end
		_save = new FlxSave();
		_save.bind("settings", #if (flixel < "5.0.0") Application.current.meta.get("company") #end);

		_songStore = new SqliteKeyValue(Path.join([System.applicationStorageDirectory, 'songStore.db']), "SongStore");

		bound = true;
		SaveData.loadSettings();
	}

	public static inline function set(key:String, value:Dynamic)
	{
		Reflect.setField(_save.data, key, value);
	}

	public static inline function get(key:String):Dynamic
	{
		return Reflect.field(_save.data, key);
	}

	/*
		public static function setSong(name:String, chart:Bytes, sound:Bytes, ctype:String = "osu")
		{
			_songStore.set(name, chart, sound, ctype);
		}

		public static function getSong(name:String, ?loadChart:Bool):Array<Dynamic>
		{
			var byteShit:Array<Dynamic> = _songStore.get(name);

			var song:Song = null;

			var sound:Sound = new Sound();
			sound.loadCompressedDataFromByteArray(byteShit[1], byteShit[1].length);

			/*
				if (loadChart)
					song = ChartLoader.loadChart()

					switch (byteShit[2])
					{
						case "osu":
							{}

						case "fnf":
							{}
			}

			return [null, sound];
	}*/
	public static function save()
	{
		_save.flush(0, (_) ->
		{
			trace("Saved");
		});
	}
}
