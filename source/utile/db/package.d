module utile.db;
import std, utile.except;

public import utile.db.mysql, utile.db.sqlite;

alias Blob = const(ubyte)[];

string DB_NULL_STRING()
{
	__gshared immutable char z;
	return (&z)[0 .. 1];
}

Blob DB_NULL_BLOB()
{
	__gshared immutable ubyte z;
	return (&z)[0 .. 1];
}

unittest
{
	{
		scope db = new SQLite(null);

		{
			Blob arr = [1, 2, 3];

			auto res = db.queryOne!Blob(`select ?;`, arr);

			assert(res == arr);
		}

		{
			auto res = db.query!(uint, string)(`select ?, ?;`, 123, `hello`).array;

			assert(res.equal(tuple(123, `hello`).only));
		}

		{
			auto res = db.queryOne!uint(`select ?;`, 123);

			assert(res == 123);
		}
	}

	version (Utile_Mysql)
	{
		MySQL db;

		auto res = db.query!(uint, string)(`select ?, ?;`, 123, `hello`);
		auto res2 = db.queryOne!uint(`select ?;`, 123);
	}
}

package:

mixin template DbBase()
{
	template query(T...)
	{
		auto query(A...)(string sql, A args)
		{
			auto stmt = prepare(sql);
			bind(stmt, args);

			static if (T.length)
			{
				return process!T(stmt);
			}
			else
			{
				process(stmt);
				auto that = this;

				struct S
				{
					auto id() => that.lastId(stmt);
					auto affected() => that.affected(stmt);
				}

				return S();
			}
		}
	}

	template queryOne(T...)
	{
		auto queryOne(A...)(string sql, A args)
		{
			auto res = query!T(sql, args);
			res.empty && throwError(`query returned no rows`);

			auto e = res.front;

			res.popFront;
			res.empty || throwError(`query returned multiple rows`);

			return e;
		}
	}
}
