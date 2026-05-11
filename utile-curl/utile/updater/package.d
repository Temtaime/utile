module utile.updater;

import std.datetime, std.process, utile, utile.curl;

import utile.updater.impl;
import utile.updater.verify;

abstract class UpdaterBase
{
	static UpdaterBase create(string url, Requests req, void delegate() onUpdate, Duration delay, Logger parent)
	{
		UpdaterBase r;

		if (SKIP_ENV in environment)
		{
			r = new SkipUpdater;
		}
		else if (VERIFY_ENV in environment)
		{
			r = new VerifyUpdater(url, req);
		}
		else
		{
			r = new Updater(url, req, onUpdate, delay);
		}

		r.logger = new SubLogger(parent, `updater`);
		return r;
	}

	abstract void check(); // checks for updates, should be called periodically
	abstract bool onStart(); // returns true if the app should exit immediately

	SubLogger logger;
}

package:

enum
{
	RETRY_DELAY = 10.seconds,
	UPDATED_TOKEN = `__UPDATED__`,

	SKIP_ENV = `UTILE_SKIP_UPDATE`,
	VERIFY_ENV = `UTILE_VERIFY_UPDATE`
}

final class SkipUpdater : UpdaterBase
{
	override bool onStart()
	{
		logger.warn!`updates are disabled`;
		return false;
	}

	override void check()
	{
	}
}
