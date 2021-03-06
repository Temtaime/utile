module utile.binary;
import std, std.typetuple, utile.misc, utile.except, utile.binary.helpers;

public import utile.binary.attrs, utile.binary.streams;

size_t writeLength(T)(ref in T value, string file = __FILE__, uint line = __LINE__)
{
	return Serializer!LengthCalcStream().write(value, true, file, line).stream.written;
}

void serializeFile(T)(string name, ref in T value, string file = __FILE__, uint line = __LINE__)
{
	scope mm = new MmFile(name, MmFile.Mode.readWriteNew, writeLength(value, file, line), null);

	mm[].Serializer!MemoryStream.write(value, true, file, line);
}

T deserializeFile(T)(string name, string file = __FILE__, uint line = __LINE__)
{
	scope mm = new MmFile(name);

	return mm[].Serializer!MemoryStream
		.read!T(true, file, line);
}

struct Serializer(Stream)
{
	this(A...)(auto ref A args)
	{
		stream = Stream(args);
	}

	T read(T)(bool ensureFullyParsed = true, string file = __FILE__, uint line = __LINE__)
			if (is(T == struct))
	{
		T value;

		auto s = SerializerImpl!(Stream, T)(&value, &stream, line, file);
		s.process!false(value, value);

		if (ensureFullyParsed)
			stream.length && throwError!`%u bytes were not parsed`(file, line, stream.length);

		return value;
	}

	ref write(T)(auto ref in T value, bool ensureNoSpaceLeft = true,
			string file = __FILE__, uint line = __LINE__) if (is(T == struct))
	{
		auto s = SerializerImpl!(Stream, const(T))(&value, &stream, line, file);
		s.process!true(value, value);

		if (ensureNoSpaceLeft)
			stream.length && throwError!`%u bytes were not occupied`(file, line, stream.length);

		return this;
	}

	Stream stream;
}

private:

struct SerializerImpl(Stream, I)
{
	void process(bool Writing, T, P)(ref T data, ref P parent)
	{
		_depth = 1;
		_names[0] = Unqual!T.stringof;

		doProcess!Writing(data, parent);
	}

	I* input;
	Stream* stream;

	uint line;
	string file;
private:
	pragma(inline, false)
	{
		@property variableName()
		{
			return _names[0 .. _depth].join('.');
		}

		bool commonError(string msg)
		{
			return throwError!"can't %s %s variable"(file, line, msg, variableName);
		}

		bool errorRead()
		{
			return commonError(`read`);
		}

		bool errorWrite()
		{
			return commonError(`write`);
		}

		bool errorRSkip()
		{
			return commonError(`skip when reading`);
		}

		bool errorWSkip()
		{
			return commonError(`skip when writing`);
		}

		bool errorCheck(T)(const(T)* tmp, const(T)* p)
		{
			return throwError!"variable %s mismatch(%s when %s expected)"(file,
					line, variableName, *tmp, *p);
		}

		bool errorValid(T)(T* p)
		{
			return throwError!"variable %s has invalid value %s"(file, line, variableName, *p);
		}
	}

	pragma(inline, true) void doProcess(bool Writing, T, P)(ref T data, ref P parent)
	{
		_depth++;
		scope (success)
			_depth--;

		auto evaluateData = tuple!(`input`, `parent`, `that`, `stream`)(input,
				&parent, &data, stream);

		enum Reading = Writing == false;
		alias Fields = aliasSeqOf!(fieldsToProcess!T());

		foreach (name; Fields)
		{
			_names[_depth] = name;

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

					static if (Writing)
						stream.wskip(cnt) || errorWSkip;
					else
						stream.rskip(cnt) || errorRSkip;
				}
			}

			{
				alias ignore = templateParamFor!(IgnoreIf, attrs);

				static if (!is(ignore == void))
				{
					if (ignore(evaluateData))
					{
						static if (Reading)
						{
							alias def = templateParamFor!(Default, attrs);

							static if (!is(def == void))
								*p = def(evaluateData);
						}

						continue;
					}
				}
			}

			static if (Reading)
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
				static if (Writing)
					stream.write(toByte(*p)) || errorWrite;
				else
					stream.read(toByte(*varPtr)) || errorRead;
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

				static if (Writing)
					*arr = p.byKeyValue.map!(a => Pair(a.key, a.value)).array;

				doProcess!Writing(aa, data);

				static if (Reading)
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

						static if (Writing)
						{
							assert(p.length <= LenAttr.max);

							elemsCnt = cast(LenAttr)p.length;
							stream.write(elemsCnt.toByte) || errorWrite;
						}
						else
							stream.read(elemsCnt.toByte) || errorRead;

						enum isRest = false;
					}
					else
					{
						uint elemsCnt = cast(uint)LenAttr(evaluateData);

						static if (Writing)
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
					static if (Writing)
					{
						stream.write(toByte(*p)) || errorWrite;

						static if (isStr && !isLen)
						{
							ubyte[1] terminator;
							stream.write(terminator) || errorWrite;
						}
					}
					else
					{
						static if (isStr && !isLen)
							stream.readstr(*varPtr) || errorRead;
						else
						{
							ubyte[] arr;

							static if (isRest)
								stream.read(arr, stream.length & ~(E.sizeof - 1)) || errorRead;
							else
								stream.read(arr, elemsCnt * E.sizeof) || errorRead;

							*varPtr = (cast(E*)arr.ptr)[0 .. arr.length / E.sizeof];
						}
					}
				}
				else
				{
					static if (Writing)
					{
						foreach (ref v; *p)
							doProcess!Writing(v, data);
					}
					else
					{
						static if (isRest)
						{
							while (stream.length)
							{
								E v;
								doProcess!Writing(v, data);
								*varPtr ~= v;
							}
						}
						else
						{
							static if (isDyn)
							{
								foreach (_; 0 .. elemsCnt)
								{
									E v;
									doProcess!Writing(v, data);
									*varPtr ~= v;
								}
							}
							else
								foreach (ref v; *varPtr)
									doProcess!Writing(v, data);
						}
					}
				}
			}
			else
				doProcess!Writing(*p, data);

			static if (Reading)
			{
				static if (is(typeof(tmp)))
				{
					tmp == *p || errorCheck(&tmp, p);
				}

				alias validate = templateParamFor!(Validate, attrs);

				static if (!is(validate == void))
					validate(evaluateData) || errorValid(p);
			}
		}
	}

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

	enum isAttrValid(T) = is(T : SerializerAttr);

	uint _depth;
	string[64] _names;
}
