# Database Layer and SQLite

`utile.db` defines the transaction contract shared by database implementations. `utile:sqlite` provides the `SQLite` implementation, typed query helpers, incremental BLOB access, backups, and common PRAGMA settings.

```json
"dependencies": {
    "utile:sqlite": "*"
}
```

```d
import std;
import utile.db;
import utile.db.sqlite;
```

## Open a Database

`SQLite` opens an in-memory database by default. Pass a filename for a persistent database. Its constructor enables foreign keys, uses in-memory temporary storage, and sets synchronous mode to `normal`.

```d
scope db = new SQLite(`app.db`);

db.query(`
    create table if not exists users (
        id integer primary key,
        name text not null,
        active integer not null
    );
`);
```

The connection caches prepared statements by SQL text and releases them when the connection is destroyed. Use one connection from one owning thread; the wrapper does not provide synchronization.

## Parameterized Queries

`query` binds each argument to a positional `?` placeholder. It supports integral and floating-point types, `string`, and `Blob` (`const(ubyte)[]`). A pointer to a supported value binds the pointed-to value; a null pointer binds SQL `NULL`.

For statements that return no rows, `query` returns an object with the inserted row ID and the number of affected rows:

```d
auto result = db.query(
    `insert into users (name, active) values (?, ?);`,
    `Ada`,
    1
);

auto id = result.id;
assert(result.affected == 1);
```

For result sets, supply the expected column types as template arguments. The returned input range yields one value for one requested column and a tuple for multiple columns.

```d
auto users = db.query!(long, string)(
    `select id, name from users where active = ? order by id;`,
    1
).array;

foreach (user; users)
{
    long id = user[0];
    string name = user[1];
}
```

Use `queryOne!T` when exactly one row and one column are required. It throws if the query returns zero or multiple rows.

```d
auto name = db.queryOne!string(`select name from users where id = ?;`, id);
```

Consume a result range before issuing another query with the same SQL text: it owns the cached prepared statement until it is exhausted or destroyed. Convert a small result set with `.array` when that ownership should end immediately.

## Transactions

`Transaction` begins in its constructor. Call `commit` to finish it; otherwise its destructor rolls it back. Keep it scoped so rollback is reliable on exceptions.

```d
with (Transaction(db))
{
    db.query(`update users set active = ? where id = ?;`, 0, id);
    db.query(`delete from sessions where user_id = ?;`, id);

    commit;
}
```

## SQLite Operations

`SQLite.backup` copies the complete source database into another open connection.

```d
scope source = new SQLite(`app.db`);
scope backup = new SQLite(`app-backup.db`);
source.backup(backup);
```

The typed PRAGMA helpers avoid stringly-typed settings for common options:

```d
db.pragma_(JournalMode.wal);
db.pragma_(AutoVacuum.incremental);
db.busyTimeout(5.seconds);
db.pageSizeKiB = 4;
db.cacheSizeMiB = 64;
```

`pageSizeKiB` and `cacheSizeMiB` accept sizes in KiB and MiB respectively. Use `vacuum` when SQLite requires a database rebuild for a configuration change.

## Incremental BLOB I/O

`openBlob` provides a non-copyable `SQLiteBlob` handle for an existing BLOB. Its size is fixed by SQLite; write only within the current length. Pass `true` to open it for writing.

```d
db.query(`create table files (data blob not null);`);

Blob original = [1, 2, 3];
auto rowId = db.query(`insert into files (data) values (?);`, original).id;
Blob replacement = [4, 5, 6];

{
    scope blob = db.openBlob(`files`, `data`, rowId, true);
    assert(blob.length == original.length);

    blob.write(replacement);
}

assert(db.queryOne!Blob(`select data from files where rowid = ?;`, rowId) == replacement);
```

`SQLiteBlob.read(size, offset)` returns a new byte array; `read(buffer, offset)` and `write(data, offset)` operate on caller-owned storage. The handle closes automatically at scope exit and can be retargeted to a row with `reopen`.

SQLite errors and query cardinality failures throw through `utile.except`. Executable examples for parameters, transactions, PRAGMA helpers, and BLOB I/O are in [`utile-test/sqlite.d`](../utile-test/sqlite.d).
