import std, utile, utile.db.sqlite;

unittest
{
	scope db = new SQLite;

	auto t = Transaction(db);
	t.commit;
}

unittest
{
	scope db = new SQLite;

	{
		Blob arr = [1, 2, 3];

		auto res = db.queryOne!Blob(`select ?;`, arr);

		assert(res == arr);
	}

	{
		auto res = db.query!(uint, string)(`select ?, ?;`, 123, `hello`).array;

		assert(res.equal(tuple(123, `hello`).only));
	}

	assert(db.queryOne!uint(`select ? is null;`, string.init) == 0);
	assert(db.queryOne!uint(`select ? is null;`, cast(string*)null) == 1);

	{
		string s = `hello`;

		assert(db.queryOne!string(`select ?;`, s) == s);
		assert(db.queryOne!string(`select ?;`, &s) == s);
	}
}
