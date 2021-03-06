module utile.binary;
import std, std.typetuple, utile.misc, utile.except, utile.binary.helpers;

public import utile.binary.attrs, utile.binary.funcs, utile.binary.streams;

struct BinarySerializer(Stream)
{
	this(A...)(auto ref A args)
	{
		stream = Stream(args);
	}

	T read(T)(bool ensureFullyParsed = true, string file = __FILE__, uint line = __LINE__)
			if (is(T == struct))
	{
		_l = line;
		_f = file;
		_info = T.stringof;

		T t;
		process(t, t, t);

		if (ensureFullyParsed)
			stream.length && throwError!`%u extra bytes was not parsed`(file, line, stream.length);

		return t;
	}

	ref write(T)(auto ref in T t, bool ensureNoSpaceLeft = true,
			string file = __FILE__, uint line = __LINE__) if (is(T == struct))
	{
		_l = line;
		_f = file;
		_info = T.stringof;

		process!true(t, t, t);

		if (ensureNoSpaceLeft)
			stream.length && throwError!`%u extra bytes were not occupied`(file,
					line, stream.length);

		return this;
	}

	Stream stream;
private:
	debug
	{
		enum errorRead = `throwError!"can't read %s.%s variable"(_f, _l, _info, name)`;
		enum errorWrite = `throwError!"can't write %s.%s variable"(_f, _l, _info, name)`;
		enum errorRSkip = `throwError!"can't skip when reading %s.%s variable"(_f, _l, _info, name)`;
		enum errorWSkip = `throwError!"can't skip when writing %s.%s variable"(_f, _l, _info, name)`;
		enum errorCheck = `throwError!"variable %s.%s mismatch(%s when %s expected)"(_f, _l, _info, name, tmp, *p)`;
		enum errorValid = `throwError!"variable %s.%s has invalid value %s"(_f, _l, _info, name, *p)`;
	}
	else
	{
		enum errorRead = `throwError!"can't read %s"(_f, _l, _info)`;
		enum errorWrite = `throwError!"can't write %s"(_f, _l, _info)`;
		enum errorRSkip = errorRead;
		enum errorWSkip = errorWrite;
		enum errorCheck = errorRead;
		enum errorValid = errorRead;
	}

	enum checkLength = `E.sizeof * elemsCnt < 512 * 1024 * 1024 || throwError!"length of %s.%s variable is too big(%u)"(_f, _l, _info, name, elemsCnt);`;

	void process(bool isWrite = false, T, S, P)(ref T data, ref S st, ref P parent)
	{
		auto evaluateData = tuple!(`input`, `parent`, `that`, `stream`)(&st,
				&parent, &data, &stream);

		alias Fields = aliasSeqOf!(fieldsToProcess!T());

		foreach (name; Fields)
		{
			enum Elem = T.stringof ~ `.` ~ name;

			alias attrs = AliasSeq!(__traits(getAttributes, __traits(getMember, T, name)));

			debug
			{
				static assert(allSatisfy!(isAttrValid, attrs), Elem ~ ` has invalid attributes`);
			}

			auto p = &__traits(getMember, data, name);
			alias R = typeof(*p);

			{
				alias skip = templateParamFor!(Skip, attrs);

				static if (!is(skip == void))
				{
					size_t cnt = skip(evaluateData);

					static if (isWrite)
						stream.wskip(cnt) || mixin(errorWSkip);
					else
						stream.rskip(cnt) || mixin(errorRSkip);
				}
			}

			{
				alias ignore = templateParamFor!(IgnoreIf, attrs);

				static if (!is(ignore == void))
				{
					if (ignore(evaluateData))
					{
						static if (!isWrite)
						{
							alias def = templateParamFor!(Default, attrs);

							static if (!is(def == void))
								*p = def(evaluateData);
						}

						continue;
					}
				}
			}

			static if (!isWrite)
			{
				static if (is(R == immutable))
				{
					Unqual!R tmp;
					auto varPtr = &tmp;
				}
				else
					alias varPtr = p;
			}

			static if (isDataSimple!R)
			{
				static if (isWrite)
					stream.write(toByte(*p)) || mixin(errorWrite);
				else
					stream.read(toByte(*varPtr)) || mixin(errorRead);
			}
			else static if (isAssociativeArray!R)
			{
				struct Pair
				{
					Unqual!(KeyType!R) key;
					Unqual!(ValueType!R) value;
				}

				struct AA
				{
					mixin(`@(` ~ [attrs].to!string[1 .. $ - 1] ~ `) Pair[] ` ~ name ~ `;`);
				}

				AA aa;
				auto arr = &aa.tupleof[0];

				static if (isWrite)
					*arr = p.byKeyValue.map!(a => Pair(a.key, a.value)).array;

				process!isWrite(aa, st, data);

				static if (!isWrite)
					*p = map!(a => tuple(a.tupleof))(*arr).assocArray;
			}
			else static if (isArray!R)
			{
				alias E = ElementEncodingType!R;
				enum isElemSimple = isDataSimple!E;

				static assert(isElemSimple || is(E == struct), `can't serialize ` ~ Elem);

				alias LenAttr = templateParamFor!(ArrayLength, attrs);

				static if (is(LenAttr == void))
				{
					enum isRest = staticIndexOf!(ToTheEnd, attrs) >= 0;

					static if (isRest)
						static assert(name == Fields[$ - 1], Elem ~ ` is not the last field`);
				}
				else
				{
					static if (isType!LenAttr)
					{
						static assert(isUnsigned!LenAttr,
								`length must be a function or an unsigned type for ` ~ Elem);

						LenAttr elemsCnt;

						static if (isWrite)
						{
							assert(p.length <= LenAttr.max);

							elemsCnt = cast(LenAttr)p.length;
							stream.write(elemsCnt.toByte) || mixin(errorWrite);
						}
						else
							stream.read(elemsCnt.toByte) || mixin(errorRead);

						enum isRest = false;
					}
					else
					{
						uint elemsCnt = cast(uint)LenAttr(evaluateData);

						static if (isWrite)
							assert(p.length == elemsCnt);

						enum isRest = false;
					}
				}

				enum isStr = is(R : string);
				enum isLen = is(typeof(elemsCnt));
				enum isDyn = isDynamicArray!R;

				static if (isDyn)
					static assert(isStr || isLen || isRest, `length of ` ~ Elem ~ ` is unknown`);
				else
					static assert(!(isLen || isRest),
							`static array ` ~ Elem ~ ` can not have a length`);

				static if (isElemSimple)
				{
					static if (isWrite)
					{
						stream.write(toByte(*p)) || mixin(errorWrite);

						static if (isStr && !isLen)
						{
							ubyte[1] terminator;
							stream.write(terminator) || mixin(errorWrite);
						}
					}
					else
					{
						static if (isStr && !isLen)
							stream.readstr(*varPtr) || mixin(errorRead);
						else
						{
							ubyte[] arr;

							static if (isRest)
							{
								stream.read(arr, stream.length & ~(E.sizeof - 1))
									|| mixin(errorRead);
							}
							else
							{
								mixin(checkLength);

								stream.read(arr, elemsCnt * E.sizeof) || mixin(errorRead);
							}

							*varPtr = (cast(E*)arr.ptr)[0 .. arr.length / E.sizeof];
						}
					}
				}
				else
				{
					debug
					{
						auto old = _info;
						_info ~= `.` ~ name;
					}

					static if (isWrite)
					{
						foreach (ref v; *p)
							process!isWrite(v, st, data);
					}
					else
					{
						static if (isRest)
						{
							while (stream.length)
							{
								E v;
								process!isWrite(v, st, data);

								*varPtr ~= v;
							}
						}
						else
						{
							static if (isDyn)
							{
								mixin(checkLength);

								*varPtr = new E[elemsCnt];
							}

							foreach (ref v; *varPtr)
								process!isWrite(v, st, data);
						}
					}

					debug
					{
						_info = old;
					}
				}
			}
			else
			{
				debug
				{
					auto old = _info;
					_info ~= `.` ~ name;
				}

				process!isWrite(*p, st, data);

				debug
				{
					_info = old;
				}
			}

			static if (!isWrite)
			{
				static if (is(typeof(tmp)))
				{
					tmp == *p || mixin(errorCheck);
				}

				alias validate = templateParamFor!(Validate, attrs);

				static if (!is(validate == void))
					validate(evaluateData) || mixin(errorValid);
			}
		}
	}

	enum isAttrValid(T) = is(T : SerializerAttr);

	template templateParamFor(alias C, A...)
	{
		static if (A.length)
		{
			alias T = A[0];

			static if (__traits(isSame, TemplateOf!T, C))
				alias templateParamFor = TemplateArgsOf!T[0];
			else
				alias templateParamFor = templateParamFor!(C, A[1 .. $]);
		}
		else
			alias templateParamFor = void;
	}

	uint _l;
	string _f, _info;
}
