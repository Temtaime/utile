# utile

`utile` is a utility library for D, distributed as a Dub package. The root package provides the general-purpose functionality and does not link against bundled static native dependencies. Bindings that need native libraries are isolated in optional Dub subpackages.

## Installation

Add the root package for dependency-free utilities:

```json
"dependencies": {
    "utile": "*"
}
```

Add a native wrapper only when it is needed:

```json
"dependencies": {
    "utile:sqlite": "*"
}
```

## Root Package

The `utile` package re-exports its main modules through `import utile;`.

| Module | Contents |
| --- | --- |
| `utile.binary` | Struct serialization, stream implementations, and serialization attributes. |
| `utile.container` | Container helpers. |
| `utile.db` | Database base class, transactions, BLOB alias, and query mixins for implementations. |
| `utile.encrypt` | Encryption helpers. |
| `utile.except` | Exception and error-reporting helpers. |
| `utile.io` | I/O helpers. |
| `utile.log` | Logger interfaces, console logger, and sub-loggers. |
| `utile.mem` | Memory and memory-mapped file helpers. |
| `utile.misc` | General-purpose utility functions. |
| `utile.net` | IP address conversion, MTU validation, select-set support, HTTP headers, and response codes. |
| `utile.string` | String helpers. |
| `utile.time` | Application timing, duration conversion, timers, meters, and stopwatches. |

Additional root modules can be imported directly:

| Module | Contents |
| --- | --- |
| `utile.console` | Terminal color handling. |
| `utile.encoding` | Text encoding conversion, using Windows charset APIs or iconv. |
| `utile.db.mysql` | Conditional MySQL binding, enabled with the `Utile_Mysql` version. |

Detailed module documentation:

- [`utile.binary`](docs/binary.md): binary layout rules, field attributes, streams, and examples.

## Subpackages

### `utile:curl`

Bindings and higher-level request handling over curl-impersonate.

- [cURL requests and jobs](docs/curl.md)
- [Application updater](docs/updater.md)

| Module | Contents |
| --- | --- |
| `utile.curl` | cURL initialization and common HTTP enums. |
| `utile.curl.base` | Common cURL handle and transfer functionality. |
| `utile.curl.browsers` | Browser impersonation profiles. |
| `utile.curl.job` | Asynchronous transfer job abstraction. |
| `utile.curl.requests` | Request collection and lifecycle management. |
| `utile.updater` | Update-checking entry point. |
| `utile.updater.helpers` | Update helper functions. |
| `utile.updater.impl` | Download and update implementation. |
| `utile.updater.net` | Network operations used by the updater. |
| `utile.updater.verify` | Download verification flow. |

### `utile:sqlite`

SQLite implementation of `utile.db`.

| Module | Contents |
| --- | --- |
| `utile.db.sqlite` | `SQLite` connection, prepared-statement cache, typed queries, transactions, backup, and database maintenance. |
| `utile.db.sqlite.blob` | Incremental BLOB I/O through the non-copyable `SQLiteBlob` handle. |
| `utile.db.sqlite.pragmas` | Typed SQLite PRAGMA configuration, including journal mode, auto-vacuum, synchronous mode, cache/page sizing, and busy timeout. |

### `utile:zip`

ZIP archive access over miniz.

| Module | Contents |
| --- | --- |
| `utile.miniz` | `Zip` archive reader/writer. |

### `utile:web`

MicroHTTPD-based HTTP server.

| Module | Contents |
| --- | --- |
| `utile.web` | `WebServer`, route registration, and integration with `utile.net.ThreeSet`. |
| `utile.web.connection` | HTTP request and response connection abstraction. |
| `utile.web.handler` | Base request handler abstraction. |

### `utile:tun`

TUN device abstraction and Linux implementation.

| Module | Contents |
| --- | --- |
| `utile.tun` | TUN settings, device interface, and packet/frame limits. |
| `utile.tun.linux` | Linux TUN device implementation. |
| `utile.tun.sys` | System-level TUN bindings and polling support. |

### `utile:test`

Executable Dub test subpackage. It exercises the root package and all optional subpackages.

## Native Dependencies and Platforms

The repository includes sources, headers, build scripts, and prebuilt native libraries in `deps/`. Native subpackages use the bundled copies of curl-impersonate, SQLite, miniz, and MicroHTTPD.

Prebuilt dependencies are available for:

- Linux musl on x86_64 and aarch64.
- Windows on x86_64.

The root `utile` package does not require these static libraries. Add only the subpackages whose native functionality your application uses.

## Third-Party Projects

- [curl-impersonate](https://github.com/lwthiker/curl-impersonate)
- [MicroHTTPD](https://www.gnu.org/software/libmicrohttpd/)
- [miniz](https://github.com/richgel999/miniz)
- [SQLite](https://www.sqlite.org/)
