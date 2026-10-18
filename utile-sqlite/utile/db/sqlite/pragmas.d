module utile.db.sqlite.pragmas;

import std;
import utile_sqlite;

enum ForeignKeys
{
	off,
	on
}

enum TempStore
{
	default_,
	file,
	memory
}

enum Synchronous
{
	off,
	normal,
	full,
	extra
}

enum JournalMode
{
	delete_,
	truncate,
	persist,
	memory,
	wal,
	off
}

enum AutoVacuum
{
	none,
	full,
	incremental
}

package:

mixin template Pragma()
{
	void pragma_(string name, string value)
	{
		query(format!`PRAGMA %s = '%s';`(name, value));
	}

	void pragma_(T)(string name, T value) if (is(T == enum) || isIntegral!T)
	{
		query(format!`PRAGMA %s = %s;`(name, value.to!string.stripRight('_')));
	}

	void pragma_(ForeignKeys value)
	{
		pragma_(`foreign_keys`, value);
	}

	void pragma_(TempStore value)
	{
		pragma_(`temp_store`, value);
	}

	void pragma_(Synchronous value)
	{
		pragma_(`synchronous`, value);
	}

	void pragma_(JournalMode value)
	{
		pragma_(`journal_mode`, value);
	}

	void pragma_(AutoVacuum value)
	{
		pragma_(`auto_vacuum`, value);
	}

	void busyTimeout(Duration timeout)
	{
		sqlite3_busy_timeout(_db, cast(int)timeout.total!`msecs`) == SQLITE_OK || error;
	}

	void vacuum()
	{
		query(`VACUUM;`);
	}

	@property
	{
		void pageSizeKiB(uint value)
		{
			query(`PRAGMA page_size = ` ~ toKiB(value) ~ ';');
		}

		void cacheSizeMiB(uint value)
		{
			query(`PRAGMA cache_size = -` ~ toKiB(value) ~ ';');
		}
	}

private:
	static string toKiB(uint value) => to!string(value * 1024);
}
