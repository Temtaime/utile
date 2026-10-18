module utile.db.sqlite.blob;

import std.string, utile.except;

import utile_sqlite;

struct SQLiteBlob
{
	this() @disable;
	this(this) @disable;

	~this()
	{
		sqlite3_blob_close(_blob);
	}

	int length() => sqlite3_blob_bytes(_blob);

	void reopen(long rowId)
	{
		check(sqlite3_blob_reopen(_blob, rowId), `reopen`);
	}

	ubyte[] read(uint size, int offset = 0)
	{
		auto data = new ubyte[size];
		read(data, offset);
		return data;
	}

	void read(void[] data, int offset = 0)
	{
		check(sqlite3_blob_read(_blob, data.ptr, cast(int)data.length, offset), `read`);
	}

	void write(in void[] data, int offset = 0)
	{
		check(sqlite3_blob_write(_blob, data.ptr, cast(int)data.length, offset), `write`);
	}

package:
	this(sqlite3* db, sqlite3_blob* blob)
	{
		_db = db;
		_blob = blob;
	}

private:
	void check(int code, string action)
	{
		code == SQLITE_OK || throwError!`failed to %s blob: %s`(action, sqlite3_errmsg(_db).fromStringz.idup);
	}

	sqlite3* _db;
	sqlite3_blob* _blob;
}
