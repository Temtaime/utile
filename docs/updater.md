# Application Updater

`utile.updater` downloads, verifies, and replaces the running executable when the version at an HTTP URL changes. It is built on `utile:curl` and is included by that subpackage.

```d
import utile.curl;
import utile.updater;
```

## Update Endpoint Contract

The URL must serve the complete replacement executable and a `Last-Modified` HTTP header. The updater compares that timestamp with the modification time of the current executable.

| Response | Result |
| --- | --- |
| `304 Not Modified` | No update is applied. |
| `200` with the same `Last-Modified` time | No update is applied. |
| `200` with a different `Last-Modified` time | Download, verify, and install the replacement. |

The download is written next to the current executable as `<executable>.tmp`. On POSIX, its mode is copied from the current executable. It is then started in verification mode: the new process sends a HEAD request to the same URL and succeeds only when the server's `Last-Modified` matches its own file timestamp. After verification, the temporary file replaces the executable; on Windows the old file is first renamed to `<executable>.old`.

This verifies that the server is serving the expected version, not a cryptographic signature. Use HTTPS and provide a server endpoint you control.

## Start and Periodically Check

Create one `Requests` collection for both normal traffic and the updater. Call `onStart` before starting the main application; it removes a stale `.old` file and performs an initial check. If it returns `true`, exit the process immediately.

```d
import std;
import utile;
import utile.curl;
import utile.updater;

final class App
{
    this()
    {
        _requests = new Requests(logger);
        _updater = UpdaterBase.create(
            `https://updates.example.com/my-app.exe`,
            _requests,
            &stop,
            6.hours,
            logger
        );
    }

    void run()
    {
        if (_updater.onStart)
            return;

        _run = true;

        while (_run)
        {
            _updater.check;
            _requests.wait;
            _requests.run;

            // Run the rest of the application's event loop here.
        }
    }

    void stop()
    {
        _run = false;
    }
private:
    Requests _requests;
    UpdaterBase _updater;
    bool _run;
}
```

`check` schedules the next conditional request after the delay supplied to `create`. It must be called periodically while the process is running. During `onStart`, a failed request is retried after ten seconds up to five times; the error state then ends the startup check so an unavailable update server does not block application startup. In periodic operation, `check` continues to schedule requests, and a successful response does not reset the retry counter.

The `onUpdate` callback is invoked after the verified replacement is installed. It should stop the application immediately so the new executable can be launched normally on the next start.

## Operational Switches

| Environment variable | Effect |
| --- | --- |
| `UTILE_SKIP_UPDATE` | Disables update checks and installation. |
| `UTILE_VERIFY_UPDATE` | Internal verification mode used by the downloaded executable. Do not set it for normal application launches. |

The updater logs under the `updater` sub-logger. Network transfers use the supplied `Requests` instance, so its connection limits and event-loop integration apply unchanged.
