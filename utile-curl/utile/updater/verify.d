module utile.updater.verify;

import std.datetime, std.process, std.stdio;
import utile, utile.curl, utile.updater.helpers;

import utile.updater;

package:

class VerifyUpdater : UpdaterBase
{
	this(string url, Requests req)
	{
		_url = url;
		_req = req;
		_helpers = new UpdaterHelpers;

		_func = TimerFunc(Duration.init, &onRequest);
	}

	override bool onStart()
	{
		logger.info!`verifying update ...`;
		loop;

		if (_hasUpdate)
		{
			logger.fatal!`newer version found`;
		}
		else
		{
			stderr.write(UPDATED_TOKEN);
		}

		return true;
	}

	override void check()
	{
		assert(false);
	}

protected:
	bool onCheck(Blob, SysTime date)
	{
		_hasUpdate = _helpers.dateModified != date;
		return true;
	}

final:
	void loop() => timerLoop(&loopImpl);

	void reset(Duration delay = RETRY_DELAY) nothrow
	{
		_func = TimerFunc(delay, &onRequest);
	}

	bool _hasUpdate;

	TimerFunc _func;
	UpdaterHelpers _helpers;
private:
	static srTime(Job j)
	{
		if (auto p = HeaderNormalized.lastModified in j.responseHeaders)
		{
			return parseHttpDate(*p);
		}

		throwError!`missing %s header in response`(Header.lastModified);
	}

	void onRequest()
	{
		auto j = _req.create(_url);

		j.header(Header.ifModifiedSince, _helpers.dateModified.toHttpDate);
		j.onComplete = &onResponse;
	}

	void onResponse(Job e)
	{
		if (!e.hasError)
		{
			try
			{
				auto date = srTime(e);
				auto data = e.code == 304 ? null : e.data;

				if (onCheck(data, date))
				{
					_done = true;
					return;
				}
			}
			catch (Exception ex)
			{
				logger.error(ex.msg);
			}
		}

		reset;
	}

	bool loopImpl()
	{
		_func.check;

		_req.wait;
		_req.run;

		return _done;
	}

	string _url;
	Requests _req;

	bool _done;
}
