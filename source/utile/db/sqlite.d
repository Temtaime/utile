module utile.db.sqlite;
import std, core.sync.mutex, core.sync.rwmutex, etc.c.sqlite3, utile.except, utile.db, utile.misc;

final class SQLite
{
	this(string name)
	{
		const(char)* p;
		auto flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE;

		if (name.empty)
		{
			flags |= SQLITE_OPEN_MEMORY;
		}
		else
			p = name.toStringz;

		sqlite3_open_v2(p, &_db, flags, null) == SQLITE_OK || error;

		exec(`pragma temp_store = MEMORY;`);
		exec(`pragma synchronous = NORMAL;`);
	}

	~this()
	{
		_cache.byValue.each!(a => remove(a));
		sqlite3_close(_db);
	}

	void backup(SQLite dest)
	{
		auto bk = sqlite3_backup_init(dest._db, MainDb, _db, MainDb);
		bk || throwError(`cannot init backup`);

		scope (exit)
		{
			sqlite3_backup_finish(bk);
		}

		sqlite3_backup_step(bk, -1) == SQLITE_DONE || error;
	}

	static Blob blobNull() => ( & _null)[0 .. 0];
	static string textNull() => cast(string)blobNull;

	void begin() => exec(`begin;`);
	void commit() => exec(`commit;`);
	void rollback() => exec(`rollback;`);

	mixin DbBase;
private:
	enum immutable(char)[4] MainDb = `main`;

	void exec(const(char)* sql)
	{
		char* msg;
		sqlite3_exec(_db, sql, null, null, &msg);

		if (msg)
		{
			auto s = msg.fromStringz.idup;
			sqlite3_free(msg);

			throwError!`error executing query: %s`(s);
		}
	}

	void process(sqlite3_stmt* stmt)
	{
		execute(stmt);
		reset(stmt);
	}

	auto process(A...)(sqlite3_stmt* stmt)
	{
		auto self = this; // TODO: DMD BUG

		struct S
		{
			this(this) @disable;

			~this() => self.reset(stmt);

			const empty() => !_hasRow;

			void popFront()
			in
			{
				assert(_hasRow);
			}
			do
			{
				_hasRow = self.execute(stmt);
			}

			auto array()
			{
				ReturnType!front[] res;

				for (; _hasRow; popFront)
				{
					res ~= front;
				}

				return res;
			}

			auto front()
			in
			{
				assert(_hasRow);
			}
			do
			{
				Tuple!A r;

				debug
				{
					auto N = r.Types.length;
					auto cnt = sqlite3_column_count(stmt);

					cnt == N || throwError!`expected %u columns, but query returned %u`(N, cnt);
				}

				foreach (i, ref v; r)
				{
					alias T = r.Types[i];

					static if (isFloatingPoint!T)
					{
						v = cast(T)sqlite3_column_double(stmt, i);
					}
					else static if (isIntegral!T)
					{
						v = cast(T)sqlite3_column_int64(stmt, i);
					}
					else static if (is(T == string))
					{
						v = sqlite3_column_text(stmt, i)[0 .. dataLen(i)].idup;
					}
					else static if (is(T == Blob))
					{
						v = cast(Blob)sqlite3_column_blob(stmt, i)[0 .. dataLen(i)].dup;
					}
					else
						static assert(false);
				}

				static if (A.length > 1)
				{
					return r;
				}
				else
					return r[0];
			}

		private:
			auto dataLen(uint col) => sqlite3_column_bytes(stmt, col);

			bool _hasRow;
		}

		return S(execute(stmt));
	}

	auto prepare(string sql)
	{
		if (auto stmt = _cache.get(sql, null))
		{
			return stmt;
		}

		sqlite3_stmt* stmt;
		sqlite3_prepare_v2(_db, sql.toStringz, cast(uint)sql.length, &stmt, null) == SQLITE_OK || error;

		return _cache[sql] = stmt;
	}

	void bind(A...)(sqlite3_stmt* stmt, A args)
	{
		debug
		{
			auto cnt = sqlite3_bind_parameter_count(stmt);
			A.length == cnt || throwError!`expected %u parameters to bind, but %u provided`(cnt, A.length);
		}

		foreach (uint i, v; args)
		{
			alias T = Unqual!(typeof(v));

			uint code;
			uint idx = i + 1;

			static if (is(T == typeof(null)))
			{
				code = sqlite3_bind_null(stmt, idx);
			}
			else static if (isFloatingPoint!T)
			{
				code = sqlite3_bind_double(stmt, idx, v);
			}
			else static if (isIntegral!T)
			{
				code = sqlite3_bind_int64(stmt, idx, v);
			}
			else static if (is(T == string))
			{
				const(char)* p;

				if (cast(void*)v.ptr is &_null)
				{
					p = null;
				}
				else
					p = v.length ? v.ptr : cast(const(char)*)&_null;

				code = sqlite3_bind_text64(stmt, idx, p, v.length, SQLITE_TRANSIENT, SQLITE_UTF8);
			}
			else static if (is(T == Blob))
			{
				const(ubyte)* p;

				if (v.ptr is &_null)
				{
					p = null;
				}
				else
					p = v.length ? v.ptr : &_null;

				code = sqlite3_bind_blob64(stmt, idx, p, v.length, SQLITE_TRANSIENT);
			}
			else
				static assert(false);

			code == SQLITE_OK || error;
		}
	}

	auto lastId(sqlite3_stmt * ) => sqlite3_last_insert_rowid(_db);
	auto affected(sqlite3_stmt * ) => sqlite3_changes(_db);
private:
	void reset(sqlite3_stmt* stmt)
	{
		sqlite3_reset(stmt);
	}

	void remove(sqlite3_stmt* stmt)
	{
		sqlite3_finalize(stmt);
	}

	bool execute(sqlite3_stmt* stmt)
	{
		auto res = sqlite3_step(stmt);
		res == SQLITE_ROW || res == SQLITE_DONE || error;
		return res == SQLITE_ROW;
	}

	bool error()
	{
		return throwError(sqlite3_errmsg(_db).fromStringz.idup);
	}

	sqlite3* _db;
	sqlite3_stmt*[string] _cache;

	immutable __gshared ubyte _null;
}
