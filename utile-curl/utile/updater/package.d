module utile.updater;

import std.datetime, utile, utile.curl, utile.updater.helpers;

enum RETRY_DELAY = 30.seconds;

final class Updater
{
	this(string url, Requests req, void delegate() onUpdate, Duration delay, Logger parent)
	{
		_url = url;
		_req = req;
		_delay = delay;

		_helpers = new UpdaterHelpers;
		_logger = new SubLogger(parent, `updater`);

		_func = TimerFunc(Duration.init, &onRequest);
	}

	bool isUpdateCompleted()
	{
		_func.check;
		return _updated;
	}

private:
	mixin publicProperty!(bool, `isVersionActual`);

	bool failed(Job j)
	{
		if (j.isError)
		{
			_logger.error!`update failed with code %u`(j.code);

			_func = TimerFunc(RETRY_DELAY, &onRequest);
			return true;
		}

		return false;
	}

	void onRequest()
	{
		auto job = _req.makeJob(_url);

		job.method = Method.head;
		job.onComplete = &onReceiveHeaders;

		_logger.info!`checking for updates ...`;
	}

	void onReceiveHeaders(Job job)
	{
		if (failed(job))
		{
			return;
		}

		auto time = job
			.responseHeaders[`last-modified`]
			.parseHTTPDate;

		if (_helpers.isNewer(time))
		{
			_logger.info3!`update is available, downloading ...`;

			job = _req.makeJob(_url);
			job.onComplete = &onReceiveData;
		}
		else
		{
			_func = TimerFunc(_delay, &onRequest);

			_logger.info2!`no update is available`;
			_isVersionActual = true;
		}
	}

	void onReceiveData(Job job)
	{
		if (failed(job))
		{
			return;
		}

		_helpers.onUpdateData(job.data);
		_updated = true;
	}

	TimerFunc _func;
	UpdaterHelpers _helpers;
	SubLogger _logger;

	const
	{
		string _url;
		Duration _delay;
	}

	Requests _req;
	bool _updated;
}
