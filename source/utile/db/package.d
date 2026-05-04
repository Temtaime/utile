module utile.db;
import std, utile.except;

alias Blob = const(ubyte)[];

abstract class Db
{
	abstract void begin();
	abstract void end();
	abstract void rollback();
}

struct Transaction
{
	this(Db db)
	{
		_db = db;
		_db.begin;
	}

	~this()
	{
		if (_db)
		{
			_db.rollback;
		}
	}

	void commit()
	{
		_db.end;
		_db = null;
	}

private:
	Db _db;
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
				auto self = this;

				struct S
				{
					auto id() => self.lastId(stmt);
					auto affected() => self.affected(stmt);
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
