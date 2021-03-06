module utile.binary.funcs;
import std.mmfile, utile.except, utile.binary;

// auto binaryWriteLen(T)(auto ref in T data, string f = __FILE__, uint l = __LINE__)
// {
// 	struct LengthCalc
// 	{
// 		bool write(in ubyte[] v)
// 		{
// 			length += v.length;
// 			return true;
// 		}

// 		bool wskip(size_t cnt)
// 		{
// 			length += cnt;
// 			return true;
// 		}

// 		size_t length;
// 	}

// 	auto bs = BinarySerializer!LengthCalc();
// 	return bs.write(data, f, l).stream.length;
// }
