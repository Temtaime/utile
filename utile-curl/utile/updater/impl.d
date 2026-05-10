module utile.updater.impl;

import std, utile, utile.curl, utile.updater.helpers;

import utile.updater, utile.updater.verify;

package:

final class Updater : VerifyUpdater
{
	this(string url, Requests req, void delegate() onUpdate, Duration delay)
	{
		super(url, req);

		_delay = delay;
		_onUpdate = onUpdate;
	}

	override bool onStart()
	{
		loop;
		return _hasUpdate;
	}

	override void check() => _func.check;
protected:
	override void onCheck()
	{
		if (_hasUpdate)
		{
			logger.info2!`newer version found, downloading ...`;

			auto j = makeJob;
			j.onComplete = a => wrap(&onReceiveData, a);
		}
		else
		{
			_done = true;
			reset(_delay);
		}
	}

private:
	void onReceiveData(Job job)
	{
		logger.info3!`verifying downloaded binary ...`;

		_helpers.unpack(job.data, srTime(job));

		if (verify)
		{
			logger.info2!`update verified successfully`;

			_onUpdate();
			_done = true;
		}
		else
			reset;
	}

	bool verify()
	{
		auto inp = File.tmpfile;
		auto output = File.tmpfile;
		auto error = File.tmpfile;

		auto pid = spawnProcess(
			_helpers.tmp,
			inp,
			output,
			error,
			[VERIFY_ENV: null],
			Config.retainStdout | Config.retainStderr | Config.suppressConsole
		);

		int code = pid.wait;

		if (code || error.asTxt != UPDATED_TOKEN)
		{
			logger.error!"verification failed with code %d:\n%s"(code, output.asTxt);
			return false;
		}

		return true;
	}

	Duration _delay;
	void delegate() _onUpdate;
}
