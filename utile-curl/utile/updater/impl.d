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
		_helpers.cleanup;
		loop;
		return _state == State.updated;
	}

	override void check() => _func.check;
protected:
	override void onRequest(Job)
	{
	}

	override Duration checkDelay() nothrow => _delay;

	override void doUpdate(Blob data, SysTime date)
	{
		logger.info2!`update found !`;
		logger.info3!`verifying downloaded binary ...`;

		_helpers.unpack(data, date);
		_helpers.verify(logger);
		_helpers.apply;

		// exit app immediately after update is applied
		_onUpdate();
	}

private:
	Duration _delay;
	void delegate() _onUpdate;
}
