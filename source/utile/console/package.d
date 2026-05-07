module utile.console;

import std;
import core.stdc.stdio : fileno, stdout, stderr;

version (Windows)
{
	import core.sys.windows.wincon;
	import core.sys.windows.windows;
}
else
{
	import core.sys.posix.unistd;
}

enum string[17] COLOR_NAMES = [
		`none`,
		`black`,
		`darkRed`,
		`darkGreen`,
		`darkYellow`,
		`darkBlue`,
		`darkMagenta`,
		`darkCyan`,
		`gray`,
		`darkGray`,
		`red`,
		`green`,
		`yellow`,
		`blue`,
		`magenta`,
		`cyan`,
		`white`
	];

mixin(genColors(`Fg`, 0));
mixin(genColors(`Bg`, COLOR_BITS));

struct Colorizer
{
nothrow:
	this(FILE* stream, ushort color)
	{
		_stream = stream;

		_fg = color & ((1 << COLOR_BITS) - 1);
		_bg = (color >> COLOR_BITS) & ((1 << COLOR_BITS) - 1);

		assert(_fg < COLOR_NAMES.length);
		assert(_bg < COLOR_NAMES.length);

		version (Windows)
		{
			if (isTerminal(_stream))
			{
				auto con = GetStdHandle(_stream == stdout ? STD_OUTPUT_HANDLE : STD_ERROR_HANDLE);

				if (con != INVALID_HANDLE_VALUE && GetConsoleScreenBufferInfo(con, &_csbi))
				{
					SetConsoleTextAttribute(_console = con, makeAttrs(_fg, _bg, _csbi.wAttributes));
				}
			}
		}
		else
		{
			fprintf(_stream, "\x1B[39;49;%u;%um", shift(_fg, 30, 90), shift(_bg, 40, 100));
		}
	}

	~this()
	{
		fflush(_stream);

		version (Windows)
		{
			if (_console != INVALID_HANDLE_VALUE)
			{
				SetConsoleTextAttribute(_console, _csbi.wAttributes);
			}
		}
		else
		{
			fputs("\x1B[39;49m\x1B[K", _stream);
		}
	}

private:
	FILE* _stream;

	version (Windows)
	{
		HANDLE _console = INVALID_HANDLE_VALUE;
		CONSOLE_SCREEN_BUFFER_INFO _csbi;
	}

	ubyte _fg;
	ubyte _bg;
}

nothrow:

bool isTerminal(FILE* file)
{
	version (Windows)
	{
		alias F = _isatty;
	}
	else
	{
		alias F = isatty;
	}

	return F(fileno(file)) && (file == stdout || file == stderr);
}

private:

enum COLOR_BITS = 5;

string genColors(string name, ubyte offset)
{
	string result = `enum ` ~ name ~ ` : ushort {`;

	foreach (i, color; COLOR_NAMES)
	{
		result ~= color ~ ` = ` ~ (i << offset).to!string ~ `,`;
	}

	return result ~ `}`;
}

uint shift(ubyte val, ubyte normal, ubyte bright)
{
	if (val == 0)
	{
		return 91 + normal;
	}

	if (--val >= 8)
	{
		return (val - 8) + bright;
	}

	return val + normal;
}

version (Windows)  :  // formatter bug

extern (C) int _isatty(int fd);

string genTable(string name, string base)
{
	string result = `static immutable ushort[17] ` ~ name ~ `_TABLE = [ 0, 0,`;

	foreach (i; 0 .. 2)
	{
		foreach (mask; 1 .. 8)
		{
			string s = only(`RED`, `GREEN`, `BLUE`)
				.enumerate
				.filter!(a => mask & (1 << a.index))
				.map!(a => base ~ a.value)
				.join(`|`);

			if (i == 1)
			{
				result ~= base ~ `INTENSITY |`;
			}

			result ~= s ~ ",\n";
		}

		if (i == 0)
		{
			result ~= base ~ "INTENSITY,\n";
		}
	}

	return result ~ `];`;
}

mixin(genTable(`FG`, `FOREGROUND_`));
mixin(genTable(`BG`, `BACKGROUND_`));

enum OTHER_ATTRS = [
		COMMON_LVB_LEADING_BYTE,
		COMMON_LVB_TRAILING_BYTE,
		COMMON_LVB_GRID_HORIZONTAL,
		COMMON_LVB_GRID_LVERTICAL,
		COMMON_LVB_GRID_RVERTICAL,
		COMMON_LVB_REVERSE_VIDEO,
		COMMON_LVB_UNDERSCORE
	];

ushort makeAttrs(ubyte FG, ubyte BG, ushort attrs)
{
	enum ALL_OTHER_ATTRS = OTHER_ATTRS.reduce!((a, b) => a | b);

	ushort result = attrs & ALL_OTHER_ATTRS;

	static foreach (s; only(`FG`, `BG`))
	{
		mixin(`result |= ` ~ s ~ ` ? ` ~ s ~ `_TABLE[` ~ s ~ `] : (attrs & ` ~ s ~ `_TABLE.back);`);
	}

	return result;
}
