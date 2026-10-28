# Binary Serialization

`utile.binary` serializes D structs to and from a compact binary layout. It is useful for file formats and protocol payloads whose layout is controlled by the application.

Import it directly or through the root package:

```d
import utile.binary;
```

## Model and Limits

The serializer walks serializable public fields in declaration/layout order. Nested structs are processed recursively. Basic values and fixed arrays of basic values are copied as their in-memory bytes, so multi-byte values use the host byte order. Most D numeric types have fixed sizes; avoid platform-dependent types such as `size_t` when the data must be shared across architectures. Do not use it as a portable cross-architecture or untrusted-input format without defining and validating that contract yourself.

Supported field shapes are:

| Shape | Encoding |
| --- | --- |
| Basic value or fixed array of basic values | Raw bytes |
| Struct | Fields processed recursively |
| Pointer to a struct | Presence flag followed by the pointed-to struct |
| Dynamic array | A length prefix, a caller-provided length, or the remaining input |
| Associative array | Array of key/value pairs; requires an array-length attribute |
| String | NUL-terminated by default |

Only structs can be top-level values. Functions and fields marked `@Ignored` are not serialized. A `static immutable` field is serialized and checked against its declared value while reading. At a shared offset, such as a union, one field is selected rather than serializing every overlapping member; avoid unions in a stable format unless that selection is intentional.

## Quick Start

Use `serializeMem` to create a payload and `deserializeMem` to parse it. The default read checks that every input byte was consumed.

```d
import utile.binary;

struct Header
{
    uint id;
    string name;
}

auto bytes = Header(42, `node`).serializeMem;
auto header = bytes.deserializeMem!Header;

assert(header.id == 42);
assert(header.name == `node`);

// Little-endian bytes: 2A 00 00 00 6E 6F 64 65 00
```

This writes `id` as four native-endian bytes, then the UTF-8 bytes for `name` and a trailing zero byte. See the [round-trip test](../utile-test/binary.d#L12-L38) for the complete expected payload.

## Arrays and Strings

Dynamic arrays must state how their extent is represented. `ArrayLength!T` writes and reads an unsigned element-count prefix. `ArrayLength!function` uses a size already available from the surrounding value. `ToTheEnd` consumes all remaining bytes and is consequently permitted only on the final field.

```d
import utile.binary;

struct Packet
{
    @(ArrayLength!ushort) ubyte[] payload;
    @ToTheEnd ushort[] trailer;
}

auto packet = Packet([1, 2, 3], [0x1234]);
auto copy = packet.serializeMem.deserializeMem!Packet;
assert(copy == packet);

// Little-endian bytes: 03 00 01 02 03 34 12
//                    ^^^^^ count  ^^^^^^^ trailer, read with @ToTheEnd
```

Strings are NUL-terminated unless `ArrayLength` or `ToTheEnd` makes their length explicit. Add `@ZeroTerminated` to use NUL termination for a byte array, or combine it with `ArrayLength` for a fixed-width, zero-padded string field.

```d
struct NameRecord
{
    @(ArrayLength!(_ => 16), ZeroTerminated) string name;
}

// NameRecord(`abc`).serializeMem:
// 61 62 63 00 00 00 00 00 00 00 00 00 00 00 00 00
```

`name` occupies exactly 16 bytes. When shorter, it is written with a terminator and skipped bytes; when it fills the field, no terminator is added. More string and array cases are covered in the [test suite](../utile-test/binary.d#L40-L112).

## Field Attributes

Attributes control the wire layout and read-time checks.

| Attribute | Effect |
| --- | --- |
| `@Ignored` | Excludes the field. |
| `@ArrayLength!T` | Prefixes a dynamic array with an unsigned count of type `T`. |
| `@ArrayLength!function` | Uses a function result as the array length; the function receives `input`, `parent`, `that`, and `stream`. |
| `@ToTheEnd` | Reads the final array field from the remaining stream. |
| `@ZeroTerminated` | Treats an array as NUL-terminated. |
| `@Skip!function` | Skips a computed number of bytes before this field. |
| `@IgnoreIf!function` | Omits the field when the predicate is true. |
| `@Default!function` | Sets a skipped-on-read field to a computed value. Use with `IgnoreIf`. |
| `@Validate!function` | Rejects a read value when the predicate is false. |

The `input`, `parent`, `that`, and `stream` arguments provided to attribute functions expose the root input, containing struct, struct whose field is being processed, and active stream respectively. At the top level, `parent` and `that` refer to the same struct. For example, a field can be conditioned on another field in the same struct:

```d
struct OptionalData
{
    bool hasData;
    @(IgnoreIf!(a => !a.that.hasData), Default!(_ => cast(ubyte)0)) ubyte data;
}
```

## Streams and Files

`Serializer!Stream` lets an application provide a stream implementation. For reading, it needs `read`, `readstr`, `rskip`, and `length`; for writing, it needs `write`, `wskip`, and `length`. Operations return `false` when they cannot complete, which the serializer converts to an exception identifying the field.

Built-in streams cover the usual cases:

| Stream | Use |
| --- | --- |
| `MemoryStream` | Read from or write into a fixed memory buffer. |
| `AppendStream` | Build a growing in-memory byte array. Used by `serializeMem`. |
| `LengthCalcStream` | Calculate the encoded byte count. Used by `writeLength`. |
| `FileStream` | Read from or write to `std.stdio.File`. |

`serializeFile` first calculates the required size and writes the result to a new file. `deserializeFile` reads a complete serialized struct from a file. For a preallocated buffer or custom transport, create a serializer explicitly:

```d
ubyte[64] buffer;
auto writer = Serializer!MemoryStream(buffer[]);
writer.write(Header(7, `cache`));

auto reader = Serializer!MemoryStream(buffer[]);
auto header = reader.read!Header;
```

`write` verifies that the destination buffer has no unused bytes by default. Pass `false` as its second argument when writing a value into the beginning of a larger buffer. Likewise, pass `false` to `read` or `deserializeMem` only when trailing input is valid for the caller's protocol.

## BMP Header Example

The following header covers the common uncompressed 24-bit BMP layout: a 14-byte file header followed by the 40-byte `BITMAPINFOHEADER`. `ArrayLength` calculates the pixel-data length from the dimensions, bit depth, and four-byte row alignment.

```d
struct Bmp
{
    size_t pixelsLength() const
    {
        long rowLength = (cast(long)width * bitsPerPixel + 31) / 32 * 4;
        return cast(size_t)(rowLength * abs(height));
    }

    // `static immutable` fields are read and checked against their value.
    static immutable char[2] signature = `BM`;
    uint fileSize;
    ushort reserved1;
    ushort reserved2;
    uint pixelsOffset;

    uint dibHeaderSize;
    int width;
    int height;
    ushort planes;
    ushort bitsPerPixel;
    uint compression;
    uint imageSize;
    int xPixelsPerMeter;
    int yPixelsPerMeter;
    uint colorsUsed;
    uint colorsImportant;

    @ArrayLength!(a => a.that.pixelsLength) ubyte[] pixels;
}

// First 14 bytes for the linked example:
// 42 4D             // signature: static immutable `BM`
// F6 D4 01 00       // fileSize: 120_054, little-endian uint
// 00 00 00 00       // reserved1, reserved2
// 36 00 00 00       // pixelsOffset: 54
```

BMP stores these fields little-endian, so this example targets the supported little-endian platforms. `signature` is checked by the deserializer itself: a value other than `BM` raises an error. The computed length means an inconsistent file is rejected instead of silently treating arbitrary trailing bytes as pixels. The [integration test](../utile-test/binary.d#L294-L345) downloads [`bmp_24.bmp`](https://people.math.sc.edu/Burkardt/data/bmp/bmp_24.bmp), parses it with `deserializeMem`, and verifies its `200 x 200` dimensions and 24-bit pixel depth.

## Error Handling

Insufficient input, an undersized output buffer, invalid validation results, and unexpected trailing bytes throw through `utile.except`. Error messages include the nested field path, so schema failures can be located without manually tracking byte offsets.

The implementation and executable examples live in [`source/utile/binary/`](../source/utile/binary/) and [`utile-test/binary.d`](../utile-test/binary.d).
