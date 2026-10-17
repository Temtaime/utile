## Project overview

`utile` is a D utility library managed by Dub. The root package provides shared utilities; optional Dub subpackages wrap native libraries and platform interfaces.

Keep this document current whenever the project structure, packages, module boundaries, or dependency relationships change.

## Source conventions

These rules incorporate `.github/copilot-instructions.md` and apply to all source changes.

- In structs and classes, declare public constructors and methods first. Place private members after a `private:` label, with private methods before fields.
- Prefer `=>` bodies for single-expression functions and properties where applicable.
- Declare POD types (`bool`, integer and floating-point types, etc.) and `string` explicitly; use `auto` for other types.
- When the context accepts an implicit boolean conversion, do not add an explicit comparison to `null` or zero.
- Omit parentheses when calling zero-argument functions.
- Do not rebuild the project when changes are limited to shader resources in `source/perfontain/shader/resource/*.c`; shaders compile at runtime.

1. Prefix private struct/class fields with `_`.
2. Prefer compact error checks such as `foo() || throwError!`foo failed`();` and `auto code = foo(); code && throwError!`foo failed, error is %d`(code);`. Include relevant context when useful; otherwise keep messages short.
3. Use `logger` methods rather than `writeln`; choose `info`, `info2`, `info3`, `dbg`, `warn`, `error`, or `fatal` appropriately.
4. Never use `logger.dbg`; use `logger.info` instead.
5. Prefer backtick string literals. Use double quotes only when escape sequences are needed.
6. Omit parentheses when calling zero-argument functions.
7. Use English only in source files.
8. Logging and exception messages start lowercase, preserve all-caps abbreviations such as `IP`, `MTU`, `HTTP`, and `TLS`, do not end in a period, and use ` ...` for long-running work.
9. Do not add parentheses around `&&` or `||` expressions only for precedence: `&&` already binds more tightly.

## Repository layout

- `source/utile/`: root `utile` package. Its package module re-exports common functionality: binary serialization, logging, exceptions, time, miscellaneous helpers, database abstractions, memory, strings, I/O, networking, and containers.
- `source/utile/binary/`: serializer, stream implementations, and serialization attributes. It builds on root helpers and exception handling.
- `source/utile/log/` and `source/utile/console/`: logging interfaces, console logger implementation, sub-loggers, and terminal color handling. Other modules use the global `logger` or a `SubLogger`.
- `source/utile/net/`: IP conversion, MTU validation, HTTP header utilities, response codes, and select-set support. The `web`, `curl`, and `tun` packages use these networking primitives.
- `source/utile/db/`: database interface, transaction helper, and shared query mixins. Database implementations such as SQLite extend this layer.
- `source/utile/time/`, `encoding/`, and the root utility modules: reusable time, encoding, encryption, I/O, memory, string, container, exception, and miscellaneous functionality.
- `utile-curl/`: `utile.curl` bindings and request/job abstractions over curl-impersonate. `utile.updater` is built on `utile.curl` and provides update checking, downloading, and verification.
- `utile-sqlite/`: `utile.db.sqlite`, the SQLite implementation of the root database abstraction.
- `utile-zip/`: `utile.miniz`, a ZIP archive wrapper over miniz.
- `utile-web/`: `utile.web`, a MicroHTTPD-based server with connection and handler abstractions. It uses root networking, headers, logging, and time utilities.
- `utile-tun/`: `utile.tun`, a TUN device abstraction with Linux and system-level implementations. It uses root networking for IP and MTU helpers.
- `utile-test/`: Dub test subpackage covering root and optional package functionality.
- `deps/`: scripts, headers, sources, and prebuilt libraries for native dependencies. `3rd-party/` contains vendored dependency repositories.

## Package relationships

The root `utile` package is the shared foundation. Every optional library subpackage declared in `dub.json` depends on it. `utile:curl` provides the transport layer used by `utile.updater`; `utile:sqlite` implements `utile.db`; `utile:web` and `utile:tun` use `utile.net`; and `utile:zip` uses shared exception handling. The `utile:test` subpackage imports the root package and all optional subpackages to exercise their public APIs.
