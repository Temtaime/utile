module utile.binary.streams;
import std.traits, std.stdio, std.mmfile, utile.binary, utile.misc, utile.except;

struct MemoryStream
{
	this(in void[] data)
	{
		_p = cast(ubyte*)data.ptr;
		_end = _p + data.length;
	}

	bool read(ubyte[] v)
	{
		if (length < v.length)
			return false;

		v[] = _p[0 .. v.length];
		_p += v.length;

		return true;
	}

	bool read(ref ubyte[] v, size_t len)
	{
		if (length < len)
		{
			return false;
		}

		v = _p[0 .. len].dup;
		_p += len;

		return true;
	}

	bool readstr(E)(ref E[] v, size_t maxLen)
	{
		auto start = cast(E*)_p;

		for (; maxLen; maxLen--)
		{
			if (length < E.sizeof)
			{
				return false;
			}

			auto c = *cast(E*)_p;
			_p += E.sizeof;

			if (!c)
				break;
		}

		v = start[0 .. (cast(E*)_p - start) - !!maxLen].dup;
		return true;
	}

	bool write(in ubyte[] v)
	{
		if (length < v.length)
			return false;

		_p[0 .. v.length] = v;
		_p += v.length;

		return true;
	}

	bool rskip(size_t cnt)
	{
		if (length < cnt)
			return false;

		_p += cnt;
		return true;
	}

	bool wskip(size_t cnt)
	{
		if (length < cnt)
			return false;

		_p += cnt;
		return true;
	}

	const data() => _p[0 .. length];
	const length() => _end - _p;
private:
	ubyte* _p, _end;
}

struct AppendStream
{
	bool write(in ubyte[] v)
	{
		data ~= v;
		return true;
	}

	bool wskip(size_t cnt)
	{
		data.length += cnt;
		return true;
	}

	const length() => 0;

	ubyte[] data;
}

struct LengthCalcStream
{
	bool write(in ubyte[] v)
	{
		_written += v.length;
		return true;
	}

	bool wskip(size_t cnt)
	{
		_written += cnt;
		return true;
	}

	const length() => 0;
private:
	mixin publicProperty!(size_t, `written`);
}

struct FileStream
{
	this(ref File f)
	{
		_f = &f;
	}

	bool read(ubyte[] v) => _f.rawRead(v).length == v.length;

	bool read(ref ubyte[] v, size_t len) // FIXME ?
	{
		v = new ubyte[len];
		return read(v);
	}

	bool readstr(E)(ref E[] v, size_t maxLen)
	{
		Unqual!E e;

		for (; maxLen; maxLen--)
		{
			if (read(e.toByte))
			{
				if (e)
				{
					v ~= e;
				}
				else
					break;
			}
			else
				return false;
		}

		return true;
	}

	bool write(in ubyte[] v)
	{
		_f.rawWrite(v);
		return true;
	}

	bool rskip(size_t cnt)
	{
		if (cnt)
		{
			_f.seek(cnt - 1, SEEK_CUR);

			ubyte v;
			return _f.rawRead(v.toByte).length == 1;
		}

		return true;
	}

	bool wskip(size_t cnt)
	{
		if (cnt)
		{
			_f.seek(cnt - 1, SEEK_CUR);

			ubyte v;
			_f.rawWrite(v.toByte);
		}

		return true;
	}

	auto length() => _f.size - _f.tell;
private:
	File* _f;
}
