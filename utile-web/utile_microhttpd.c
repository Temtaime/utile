#include <microhttpd.h>

enum
{
	_MHD_SIZE_UNKNOWN = MHD_SIZE_UNKNOWN,
	_FD_SETSIZE = FD_SETSIZE
};

// FIXME: private APIs

#include <stdbool.h>

bool MHD_connection_set_cork_state_(struct MHD_Connection *connection, bool cork_state);
bool MHD_connection_set_nodelay_state_(struct MHD_Connection *connection, bool nodelay_state);
