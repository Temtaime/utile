module utile.updater.verify;

import std.datetime, std.process, std.stdio;
import utile, utile.curl, utile.net.headers, utile.updater.helpers;

import utile.updater, utile.updater.net;

package:

final class VerifyUpdater : NetUpdater
{
	this(string url, Requests req)
	{
		super(url, req);
	}

	override bool onStart()
	{
		logger.info!`verifying update ...`;
		loop;

		if (state == State.ok)
		{
			stderr.write(UPDATED_TOKEN);
		}
		else
		{
			logger.fatal!`cannot check if current version is up to date`;
		}

		return true;
	}

	override void check() => assert(false);

protected:
	override Duration checkDelay() nothrow => RETRY_DELAY;

	override void onRequest(Job j) => j.noBody;
	override void doUpdate(Blob, SysTime) => assert(false);
}
