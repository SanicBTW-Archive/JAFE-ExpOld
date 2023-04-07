package base.system;

#if sys
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import haxe.Exception;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.io.Path;
import sys.FileSystem;
import sys.db.Connection;
import sys.db.ResultSet;
import sys.db.Sqlite;
import sys.io.File;
import sys.thread.Mutex;
import sys.thread.Tls;

/**
 * A string-based key value store using Sqlite as backend.
 * This is expected to be thread safe.
 *
 * Hard coded to match target usage.
 *
 * @author Ceramic
 */
class SqliteKeyValue implements IFlxDestroyable
{
	private static final APPEND_ENTRIES_LIMIT:Int = 128;

	private var path:String;
	private var table:String;
	private var escapedTable:String;
	private var connections:Array<Connection>;
	private var tlsConnection:Tls<Connection>;

	private var mutex:Mutex;
	private var mutexAcquiredInParent:Bool = false;

	private function getConnection():Connection
	{
		var connection:Connection = tlsConnection.value;
		if (connection == null)
		{
			connection = Sqlite.open(path);
			connections.push(connection);
			tlsConnection.value = connection;
		}
		return connection;
	}

	public function new(path:String, table:String = 'KeyValue')
	{
		mutex = new Mutex();
		mutex.acquire();
		connections = [];
		tlsConnection = new Tls();
		mutex.release();

		this.path = path;
		this.table = table;

		escapedTable = escape(table);

		if (!FileSystem.exists(Path.directory(path)))
			FileSystem.createDirectory(Path.directory(path));

		if (!FileSystem.exists(path))
			createDB();
	}

	public function set(key:String, chart:Bytes, inst:Bytes, ?voices:Bytes):Bool
	{
		if (chart == null || inst == null)
			return throw new Exception("Cannot set a NULL value");

		var escapedKey:String = escape(key);

		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('BEGIN TRANSACTION');
			connection.request('INSERT OR REPLACE INTO $escapedTable (key, chart, inst, voices) VALUES ($escapedKey, $chart, $inst, $voices)');
			connection.request('COMMIT');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to set value for key $key: $exc');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	public function remove(key:String):Bool
	{
		var escapedKey:String = escape(key);

		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('DELETE FROM $escapedTable WHERE key = $escapedKey');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to remove value for key $key: $exc');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	public function append(key:String, chart:Bytes, inst:Bytes, ?voices:Bytes):Bool
	{
		if (chart == null || inst == null)
			return throw new Exception("Cannot set a NULL value");

		var escapedKey:String = escape(key);

		mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('INSERT INTO $escapedTable (key, chart, inst, voices) VALUES ($escapedKey, $chart, $inst, $voices)');
		}
		catch (exc:Dynamic)
		{
			trace('Failed to append value for key $key: $exc');
			mutex.release();
			return false;
		}

		mutex.release();

		return true;
	}

	// Returns array of bytes, each index represents its value
	// 0 -> Chart, 1 -> Inst, 2 -> Sound (can be null)
	public function get(key:String):Array<Dynamic>
	{
		var escapedKey:String = escape(key);

		mutex.acquire();

		var data:Array<Bytes> = null;
		var numEntries:Int = 0;

		try
		{
			var connection:Connection = getConnection();
			var result:ResultSet = connection.request('SELECT (chart, inst, voices) FROM $escapedTable WHERE key = $escapedKey ORDER BY id ASC');

			for (entry in result)
			{
				if (data == null)
					data = [];

				data.insert(0, entry.chart);
				data.insert(1, entry.inst);
				data.insert(2, entry.voices);
				numEntries++;
			}
		}
		catch (exc:Dynamic)
		{
			trace('Failed to get chart or sound for key $key: $exc');
			mutex.release();
			return null;
		}

		if (numEntries > APPEND_ENTRIES_LIMIT)
		{
			mutexAcquiredInParent = true;
			set(key, data[0], data[1], data[2]);
			mutexAcquiredInParent = false;
		}

		mutex.release();
		return data != null ? data : null;
	}

	// I believe its done everytime there is a transaction, dunno if it actually works lol
	public function save():Bool
	{
		if (!mutexAcquiredInParent)
			mutex.acquire();

		try
		{
			var connection:Connection = getConnection();
			connection.request('BEGIN TRANSACTION');
			connection.request('COMMIT');
		}
		catch (exc:Dynamic)
		{
			trace('Failed saving');
			if (!mutexAcquiredInParent)
				mutex.release();
			return false;
		}

		if (!mutexAcquiredInParent)
			mutex.release();

		return true;
	}

	public function destroy():Void
	{
		mutex.acquire();
		for (connection in connections)
		{
			connection.close();
		}
		mutex.release();
	}

	// Internal use only

	private static inline function escape(token:String):String
		return "'" + StringTools.replace(token, "'", "''") + "'";

	private function createDB():Void
	{
		mutex.acquire();

		var connection:Connection = getConnection();
		connection.request('BEGIN TRANSACTION');
		connection.request('PRAGMA encoding = "UTF-8"');
		connection.request('
            CREATE TABLE $escapedTable (
                id INTEGER PRIMARY KEY,
                key TEXT NOT NULL,
                chart BLOB NOT NULL,
				inst BLOB NOT NULL,
				voices BLOB NULL
            )
        ');
		connection.request('CREATE INDEX key_idx ON $escapedTable(key)');
		connection.request('COMMIT');
		trace("Created DB");

		mutex.release();
	}
}
#end
