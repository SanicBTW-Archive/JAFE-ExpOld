package states;

import base.MusicBeatState;
import base.ScriptableState;
import base.system.Conductor;
import base.system.Controls;
import base.system.SaveFile;
import base.ui.CircularSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.Character;
import funkin.ChartLoader;
import haxe.Json;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import openfl.utils.Assets;
import states.config.KeybindsState;

using StringTools;

class RewriteMenu extends MusicBeatState
{
	// Options available
	private var options:Array<String> = ["Play", "Settings"];
	private var subOptions:Map<String, Array<Dynamic>> = [
		// bruh
		"Play" => ["List songs", "Online"],
		"Settings" => ["Keybinds"],
	];
	private var groupItems:FlxTypedGroup<CircularSpriteText>;

	// Menu essentials
	private var canPress:Bool = true;
	private var curState(default, set):SelectionState = SELECTING;
	private var curOption(default, set):Int = 0;
	private var curOptionStr:String;
	private var catStr:String;
	private var subStr:String;

	private function set_curOption(value:Int):Int
	{
		curOption += value;

		if (curOption < 0)
			curOption = groupItems.members.length - 1;
		if (curOption >= groupItems.members.length)
			curOption = 0;

		var the:Int = 0;

		for (item in groupItems)
		{
			item.selected = (item.ID == curOption);

			if (item.menuItem)
			{
				item.targetY = the - curOption;
				the++;
			}
		}

		if (groupItems.members[curOption] != null)
			curOptionStr = groupItems.members[curOption].bitmapText.text;

		return curOption;
	}

	private function set_curState(newState:SelectionState):SelectionState
	{
		canPress = false;
		if (groupItems.members.length > 0)
		{
			for (i in 0...groupItems.members.length)
			{
				groupItems.remove(groupItems.members[0], true);
			}
		}

		switch (newState)
		{
			case SELECTING:
				{
					catStr = null;
					for (i in 0...options.length)
					{
						var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, options[i]);
						item.ID = i;
						groupItems.add(item);
					}
				}
			case SUB_SELECTION:
				{
					if (curState != LISTING)
						catStr = curOptionStr;
					for (i in 0...subOptions.get(catStr).length)
					{
						var item:CircularSpriteText = new CircularSpriteText(30, 30 + (i * 55), 350, 50, FlxColor.GRAY, subOptions.get(catStr)[i]);
						item.ID = i;
						groupItems.add(item);
					}
				}
			case LISTING:
				{
					subStr = curOptionStr;
					regenListing();
				}
		}

		curOption = groupItems.length + 1;

		return curState = newState;
	}

	override public function create()
	{
		Controls.setActions(UI);

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault2"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		groupItems = new FlxTypedGroup<CircularSpriteText>();
		add(groupItems);

		curState = SELECTING;
		canPress = true;

		super.create();

		FlxG.sound.playMusic(Paths.music("freakyMenu"));
	}

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);

		if (!canPress)
			return;

		switch (curState)
		{
			case SELECTING:
				{
					switch (action)
					{
						case "confirm":
							{
								curState = SUB_SELECTION;
							}

						case "ui_up":
							curOption = -1;
						case "ui_down":
							curOption = 1;
					}
				}

			case SUB_SELECTION:
				{
					switch (action)
					{
						case "confirm":
							{
								checkSub();
							}

						case "back":
							{
								curState = SELECTING;
							}

						case "ui_up":
							curOption = -1;
						case "ui_down":
							curOption = 1;
					}
				}

			case LISTING:
				{
					switch (action)
					{
						case "confirm":
							{
								handleListing();
							}

						case "back":
							{
								curState = SUB_SELECTION;
							}

						case "ui_up":
							curOption = -1;
						case "ui_down":
							curOption = 1;
					}
				}
		}
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);

		canPress = true;
	}

	private function regenListing()
	{
		switch (catStr) {}
	}

	private function handleListing()
	{
		switch (catStr) {}
	}

	private function checkSub()
	{
		if (catStr == null)
			return;

		switch (catStr)
		{
			default:
				curState = LISTING;
		}
	}
}

enum SelectionState
{
	SELECTING;
	SUB_SELECTION;
	LISTING;
}
