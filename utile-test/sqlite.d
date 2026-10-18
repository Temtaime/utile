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

	db.pragma_(JournalMode.memory);
	db.pragma_(AutoVacuum.none);
	db.busyTimeout(1.msecs);
	db.vacuum;
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

unittest
{
	scope db = new SQLite;

	db.query(`create table blobs (data blob not null);`);

	Blob original = [1, 2, 3];
	auto rowId = db.query(`insert into blobs (data) values (?);`, original).id;
	Blob replacement = [4, 5, 6];

	{
		scope blob = db.openBlob(`blobs`, `data`, rowId, true);
		assert(blob.length == original.length);

		auto data = new ubyte[blob.length];
		blob.read(data);
		assert(data == original);

		blob.write(replacement);
	}

	assert(db.queryOne!Blob(`select data from blobs where rowid = ?;`, rowId) == replacement);
}
