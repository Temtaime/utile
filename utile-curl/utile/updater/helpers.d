module utile.updater.helpers;

import std;

enum OLD_SUFFIX = `.old`;
enum TMP_SUFFIX = `.tmp`;

import core.thread, core.sys.posix.sys.stat, utile.time;

package:

class UpdaterHelpers
{
	this()
	{
		_exePath = thisExePath;
		_oldPath = _exePath ~ OLD_SUFFIX;

		_fileModified = timeLastModified(_exePath);

		while (exists(_oldPath))
		{
			try
			{
				remove(_oldPath);
			}
			catch (Exception)
			{
				Thread.sleep(1.seconds);
			}
		}
	}

	bool isNewer(SysTime serverTime)
	{
		_serverTime = serverTime;
		return serverTime != _fileModified;
	}

	void onUpdateData(in ubyte[] data)
	{
		version (Posix)
		{
			stat_t st;
			stat(_exePath.toStringz, &st);
		}

		string tmp = _exePath ~ TMP_SUFFIX;

		data.toFile(tmp);
		setTimes(tmp, _serverTime, _serverTime);

		version (Windows)
		{
			rename(_exePath, _oldPath);
		}
		else
		{
			chmod(tmp.toStringz, st.st_mode);
		}

		rename(tmp, _exePath);
	}

private:
	immutable
	{
		string _exePath;
		string _oldPath;
		SysTime _fileModified;
	}

	SysTime _serverTime;
}
