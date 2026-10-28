# MicroHTTPD Web Server

`utile:web` is a small event-loop wrapper around MicroHTTPD. It accepts connections through `WebServer`, creates a `WebHandler` per request, and exposes request metadata through `WebConnection`.

```json
"dependencies": {
    "utile:web": "*"
}
```

```d
import utile.web;
```

## Server and Routes

`WebServer` does not create its own worker thread. Add its file descriptors to `utile.net.ThreeSet`, select, then call `run` with the selected set.

```d
import std;
import utile;
import utile.net;
import utile.net.headers;
import utile.web;

scope web = new WebServer(8080, 30.seconds, logger);
web.routes[`/upload`][`POST`] = (conn) => new UploadHandler(conn);

for (scope set = new ThreeSet; true)
{
    set.reset;
    web.fdset(set);
    set.select(100.msecs);
    web.run(set);
}
```

Routes are selected in this order:

1. Exact URL and method: `routes[`/upload`][`POST`]`.
2. URL-specific fallback: `routes[`/upload`][null]`.
3. Method-specific fallback: `routes[null][`POST`]`.
4. Global fallback: `routes[null][null]`.

The global fallback is a `404 Not Found` handler by default. `createHandler403`, `createHandler404`, and `createHandler500` are available when a route needs a standard error response.

## Handle a Request

The server constructs one handler for each request. `onReceive` is called for each non-empty request-body chunk. Once MicroHTTPD has delivered the complete body, `onResponse` is called once; send the response there.

```d
final class UploadHandler : WebHandler
{
    this(WebConnection conn)
    {
        super(conn);
    }

    override void onReceive(in ubyte[] chunk)
    {
        _received += chunk.length;
    }

    override void onResponse()
    {
        conn.responseHeaders[Header.contentType] = `text/plain`;
        conn.send(200, format!`received %u bytes`(_received));
    }
private:
    size_t _received;
}
```

`WebConnection.send(code, text)` queues a complete text response. Set `responseHeaders` before calling `send`; the map is applied to that response and then cleared. `send(chunkSize, callback)` creates a streaming `200` response. Its callback receives the offset and writable output chunk and returns the number of bytes produced.

Handlers are retained by the server until the request completes. Do not retain or use `WebConnection` after the request lifecycle ends.

## Read Request Metadata

Each handler receives its request's `WebConnection` through the base constructor.

| Property | Contents |
| --- | --- |
| `url` | Request path. |
| `method` | HTTP method. |
| `query` | URL query parameters. |
| `headers` | Request headers. |
| `cookies` | Request cookies. |
| `addr` | Client `Address`. |
| `logger` | Request-scoped sub-logger. |

Keys in `query`, `headers`, and `cookies` are normalized to lowercase. Values are strings; a repeated key retains the last value reported by MicroHTTPD.

```d
override void onResponse()
{
    auto page = conn.query.get(`page`, `1`);
    auto token = conn.headers.get(HeaderNormalized.authorization, null);

    if (token.empty)
    {
        conn.send(403, `Forbidden`);
        return;
    }

    conn.send(200, format!`page %s`(page));
}
```

## Reverse Proxies

`setClientIP` replaces the socket peer address with the first value of a request header, such as `X-Forwarded-For`:

```d
import utile.net.headers;

web.setClientIP(HeaderNormalized.xForwardedFor);
```

Configure it only when every direct client is a trusted proxy that removes or overwrites that header. Otherwise, clients can forge `conn.addr`.

The [web integration test](../utile-test/net.d#L5-L65) combines `WebServer` and `utile.curl`, covers route dispatch, query parameters, cookies, headers, client IP restoration, and a text response.
