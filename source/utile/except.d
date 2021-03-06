module utile.except;
import std.conv, std.format, std.exception;

bool throwError(string S, string File = __FILE__, uint Line = __LINE__, A...)(A args)
		if (__traits(compiles, format!S(args)))
{
	return throwError(format!S(args), File, Line);
}

bool throwError(string S, A...)(string file, uint line, A args)
		if (__traits(compiles, format!S(args)))
{
	return throwError(format!S(args), file, line);
}

bool throwError(T)(T t, string file = __FILE__, uint line = __LINE__)
{
	throw new Exception(t.to!string, file, line);
}
