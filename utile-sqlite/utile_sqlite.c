#define SQLITE_DQS 0
#define SQLITE_DEFAULT_MEMSTATUS 0
#define SQLITE_MAX_EXPR_DEPTH 0
#define SQLITE_OMIT_DEPRECATED
#define SQLITE_OMIT_PROGRESS_CALLBACK
#define SQLITE_OMIT_SHARED_CACHE
#define SQLITE_OMIT_AUTOINIT
#define SQLITE_STRICT_SUBTYPE 1

#ifdef UTILE_BUILD
	#include "../deps/sqlite/src/sqlite3.c"
#else
	#include <sqlite3.h>
#endif
