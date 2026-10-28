# cURL Requests and Jobs

`utile:curl` wraps curl-impersonate in an event-driven `Requests` collection. A collection owns every active `Job`: configure a job after `create`, then drive the collection until the job completes.

Add the subpackage and import its public module:

```json
"dependencies": {
    "utile:curl": "*"
}
```

```d
import utile.curl;
```

## Make a Request

`Requests.wait` waits for network activity and `Requests.run` advances transfers and completes finished jobs. A completed job retains its response properties, while its native curl handle has already been cleaned up.

```d
import std;
import utile;
import utile.curl;
import utile.net.headers;

scope requests = new Requests(logger);
auto job = requests.create(`https://example.com/data`);

while (!job.done)
{
    requests.wait;
    requests.run;
}

assert(!job.hasError);
assert(job.code == 200);
auto body = job.data;
```

By default, received chunks are appended to `job.data`. `hasError` is set for transport failures, aborted transfers, and HTTP status codes from 400 through 599. Response-header names in `job.responseHeaders` are normalized to lowercase. `contentLength` is populated from `Content-Length` when supplied, otherwise it is `-1`.

The executable tests cover both a local request and a public HTTPS request: [`utile-test/net.d`](../utile-test/net.d#L34-L82).

## Configure a Job

Call the configuration methods before driving `Requests.run`.

| Method | Purpose |
| --- | --- |
| `header(name, value)` | Adds an HTTP header. |
| `cookies(values)` | Sends a string associative array as the `Cookie` header. |
| `userAgent(value)` | Sets the user agent. |
| `auth(user, password)` | Sets HTTP authentication credentials. |
| `method(value)` / `noBody` | Uses a custom HTTP method or makes a HEAD-style request. |
| `range(start, end)` | Requests an inclusive byte range. |
| `etag(value)` | Sends `If-Match`. |
| `lowSpeed(speed, duration)` | Fails a transfer that remains below the configured speed. |
| `buffers(size)` | Sets curl download and upload buffer sizes. |
| `version_(Alpn)` | Selects the HTTP protocol version. |
| `impersonate(Browser, headers)` | Applies a curl-impersonate browser profile; `headers` also applies its browser headers. |

`Browser` lists the browser profiles bundled with curl-impersonate. The profile is an explicit compatibility choice, not a general replacement for application headers or authentication.

Use `utile.net.headers.Header` for outgoing standard header names. Response-header keys are lowercase, so look them up with `HeaderNormalized`:

```d
job.header(Header.accept, `application/json`);

// Read after the job completes.
auto contentType = job.responseHeaders.get(HeaderNormalized.contentType, null);
```

## Upload and Stream Data

`upload(data)` sends a fixed byte buffer. For a producer that supplies data incrementally, call `upload` and set `onRead`; return the number of bytes written into the supplied buffer. `onRead` can return `Read.pause` or `Read.abort`.

Set `onWrite` to consume response chunks without accumulating them in `job.data`. It receives the chunk and must return the number of consumed bytes. Returning `Write.pause` pauses the transfer; call `job.wakeup` after the consumer is ready to resume. Returning `Write.abort` ends the request with an error.

```d
auto job = requests.create(`https://example.com/upload`);
job.method(Method.put);
job.header(Header.contentType, `application/octet-stream`);
job.upload(cast(const(ubyte)[])`payload`);

ubyte[] response;
job.onWrite = (Job _, ubyte[] chunk)
{
    response ~= chunk;
    return cast(uint)chunk.length;
};
```

`onHeaders` runs after a complete HTTP header block is received. `onComplete` runs when the collection removes a finished job, before `done` becomes true. Exceptions from `onComplete` are logged rather than propagated.

## Integrate an Event Loop

For an application already using `utile.net.ThreeSet`, add the curl file descriptors to the same select set and call `run` after selection:

```d
for (scope set = new ThreeSet; !job.done)
{
    set.reset;
    requests.fdset(set);
    set.select(100.msecs);
    requests.run;
}
```

`Requests.maxTotalConnections` and `Requests.maxConcurrentStreams` set the corresponding curl multi-handle limits. `Requests.wakeup` may be used to wake a thread blocked in curl's polling operation.

Do not call `run`, `wait`, or mutate a `Job` concurrently from multiple threads. The collection is intended to be driven by one event-loop owner.
