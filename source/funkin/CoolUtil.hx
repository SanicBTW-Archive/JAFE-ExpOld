package funkin;

import funkin.ChartLoader;
import haxe.Json;

using StringTools;

class CoolUtil
{
	public static inline function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	public static function loadSong(rawInput:String):Song
	{
		while (!rawInput.endsWith("}"))
		{
			rawInput = rawInput.substr(0, rawInput.length - 1);
		}

		var songJson:Song = cast Json.parse(rawInput).song;
		return songJson;
	}
}
