module utile.console;
import core.stdc.stdio;

enum CC_COLOR_BITS = 5;

enum
{
	CC_FG_NONE = 0 << 0,
	CC_FG_BLACK = 1 << 0,
	CC_FG_DARK_RED = 2 << 0,
	CC_FG_DARK_GREEN = 3 << 0,
	CC_FG_DARK_YELLOW = 4 << 0,
	CC_FG_DARK_BLUE = 5 << 0,
	CC_FG_DARK_MAGENTA = 6 << 0,
	CC_FG_DARK_CYAN = 7 << 0,
	CC_FG_GRAY = 8 << 0,
	CC_FG_DARK_GRAY = 9 << 0,
	CC_FG_RED = 10 << 0,
	CC_FG_GREEN = 11 << 0,
	CC_FG_YELLOW = 12 << 0,
	CC_FG_BLUE = 13 << 0,
	CC_FG_MAGENTA = 14 << 0,
	CC_FG_CYAN = 15 << 0,
	CC_FG_WHITE = 16 << 0,

	CC_BG_NONE = 0 << CC_COLOR_BITS,
	CC_BG_BLACK = 1 << CC_COLOR_BITS,
	CC_BG_DARK_RED = 2 << CC_COLOR_BITS,
	CC_BG_DARK_GREEN = 3 << CC_COLOR_BITS,
	CC_BG_DARK_YELLOW = 4 << CC_COLOR_BITS,
	CC_BG_DARK_BLUE = 5 << CC_COLOR_BITS,
	CC_BG_DARK_MAGENTA = 6 << CC_COLOR_BITS,
	CC_BG_DARK_CYAN
		= 7 << CC_COLOR_BITS, CC_BG_GRAY = 8 << CC_COLOR_BITS,
		CC_BG_DARK_GRAY = 9 << CC_COLOR_BITS, CC_BG_RED = 10 << CC_COLOR_BITS,
		CC_BG_GREEN = 11 << CC_COLOR_BITS, CC_BG_YELLOW = 12 << CC_COLOR_BITS, CC_BG_BLUE = 13 << CC_COLOR_BITS,
		CC_BG_MAGENTA = 14 << CC_COLOR_BITS, CC_BG_CYAN = 15 << CC_COLOR_BITS,
		CC_BG_WHITE = 16 << CC_COLOR_BITS
}

extern (C):

int cc_fprintf(int color, FILE* stream, const char* format, ...);