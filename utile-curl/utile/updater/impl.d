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
		return _hasUpdate;
	}

	override void check() => _func.check;
protected:
	override bool onCheck(Blob data, SysTime date)
	{
		if (data.empty)
		{
			reset(_delay);
			return true;
		}

		logger.info2!`update found !`;
		logger.info3!`verifying downloaded binary ...`;

		_helpers.unpack(data, date);

		if (_helpers.verify(logger))
		{
			logger.info2!`update verified successfully`;

			_helpers.apply;
			_onUpdate();
			_hasUpdate = true;

			return true;
		}

		return false;
	}

private:
	Duration _delay;
	void delegate() _onUpdate;
}
