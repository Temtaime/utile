#define _NO_CRT_STDIO_INLINE
#include "lib/console-colors.h"

void print_stdout(int color, size_t len, const char* s)
{
	cc_fprintf(color, stdout, "%.*s", len, s);
}
