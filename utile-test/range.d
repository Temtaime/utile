import std, utile.range;

unittest
{
	RangeSet rs;
	rs += DataRange(0, 5);
	assert(rs.ranges == [DataRange(0, 5)]);

	// Test holes
	auto h = rs.holes(DataRange(0, 10)).array;
	assert(h == [DataRange(5, 10)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(10, 15);
	assert(rs.ranges == [DataRange(0, 5), DataRange(10, 15)]);

	// Test holes
	auto h = rs.holes(DataRange(0, 20)).array;
	assert(h == [DataRange(5, 10), DataRange(15, 20)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(10, 15);
	rs += DataRange(5, 7);
	assert(rs.ranges == [DataRange(0, 7), DataRange(10, 15)]);

	// Test holes
	auto h = rs.holes(DataRange(0, 20)).array;
	assert(h == [DataRange(7, 10), DataRange(15, 20)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(10, 15);
	rs += DataRange(5, 7);
	rs += DataRange(12, 17);
	assert(rs.ranges == [DataRange(0, 7), DataRange(10, 17)]);

	// Test holes
	auto h = rs.holes(DataRange(0, 15)).array;
	assert(h == [DataRange(7, 10)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(10, 15);
	rs += DataRange(5, 7);
	rs += DataRange(12, 17);
	rs += DataRange(6, 13);
	assert(rs.ranges == [DataRange(0, 17)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 17);
	rs += DataRange(2, 4);
	assert(rs.ranges == [DataRange(0, 17)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(10, 20);
	rs += DataRange(0, 5);
	assert(rs.ranges == [DataRange(0, 5), DataRange(10, 20)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(10, 20);
	rs += DataRange(0, 5);
	rs += DataRange(25, 30);
	assert(rs.ranges == [DataRange(0, 5), DataRange(10, 20), DataRange(25, 30)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(10, 20);
	rs += DataRange(0, 5);
	rs += DataRange(25, 30);
	rs += DataRange(0, 40);
	assert(rs.ranges == [DataRange(0, 40)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(10, 20);
	rs += DataRange(5, 8);
	assert(rs.ranges == [DataRange(5, 8), DataRange(10, 20)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(10, 20);
	rs += DataRange(5, 8);
	rs += DataRange(7, 12);
	assert(rs.ranges == [DataRange(5, 20)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(3, 5);
	rs += DataRange(4, 7);
	rs += DataRange(2, 7);
	rs += DataRange(2, 9);
	assert(rs.ranges == [DataRange(2, 9)]);
}

unittest
{
	RangeSet rs;
	// Empty set, should not have any range
	assert(!(DataRange(0, 1) in rs));

	// Add a range, check for exact match
	rs += DataRange(5, 10);
	assert(DataRange(5, 10) in rs);

	// Check for subrange
	assert(DataRange(6, 9) in rs);

	// Check for range outside
	assert(!(DataRange(0, 5) in rs));
	assert(!(DataRange(0, 4) in rs));
	assert(!(DataRange(10, 15) in rs));
	assert(!(DataRange(11, 15) in rs));

	// Check for partial overlap (should be false)
	assert(!(DataRange(8, 12) in rs));

	// Add another range, check for both
	rs += DataRange(20, 25);
	assert(DataRange(20, 25) in rs);
	assert(DataRange(22, 24) in rs);
	assert(!(DataRange(15, 20) in rs));

	// Check for range spanning two intervals (should be false)
	assert(!(DataRange(8, 22) in rs));
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 10);
	rs -= DataRange(3, 7);
	assert(rs.ranges == [DataRange(0, 3), DataRange(7, 10)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 10);
	rs -= DataRange(0, 3);
	assert(rs.ranges == [DataRange(3, 10)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 10);
	rs -= DataRange(7, 10);
	assert(rs.ranges == [DataRange(0, 7)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 10);
	rs -= DataRange(0, 10);
	assert(rs.ranges.empty);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(10, 15);
	rs -= DataRange(3, 12);
	assert(rs.ranges == [DataRange(0, 3), DataRange(12, 15)]);
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 1);
	rs += DataRange(2, 3);
	rs += DataRange(4, 6);
	rs += DataRange(7, 15);

	auto h = rs.holes(DataRange(0, 15)).array;
	assert(h == [DataRange(1, 2), DataRange(3, 4), DataRange(6, 7)]);

	rs -= DataRange(1, 10);
	assert(rs.ranges == [DataRange(0, 1), DataRange(10, 15)]);
}

unittest
{
	// Empty set, nothing should be "in"
	RangeSet rs;
	assert(!(DataRange(0, 1) in rs));
	assert(!(DataRange(10, 20) in rs));
}

unittest
{
	// Single range, test boundaries
	RangeSet rs;
	rs += DataRange(5, 10);
	assert(!(DataRange(4, 10) in rs)); // left edge outside
	assert(!(DataRange(5, 11) in rs)); // right edge outside
	assert(!(DataRange(4, 11) in rs)); // both edges outside
	assert(DataRange(5, 10) in rs); // exact match
	assert(DataRange(6, 9) in rs); // inside
}

unittest
{
	// Multiple ranges, test spanning
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(10, 15);
	assert(!(DataRange(4, 11) in rs)); // spans two ranges, should be false
	assert(!(DataRange(5, 10) in rs)); // gap between ranges
	assert(DataRange(10, 15) in rs);
	assert(DataRange(0, 5) in rs);
}

unittest
{
	// Test adjacent ranges merge
	RangeSet rs;
	rs += DataRange(0, 5);
	rs += DataRange(5, 10);
	assert(rs.ranges == [DataRange(0, 10)]); // Should merge
}

unittest
{
	RangeSet rs;
	rs += DataRange(0, 10);
	rs -= DataRange(5, 10);
	assert(rs.ranges == [DataRange(0, 5)]);
}

unittest
{
	RangeSet rs;
	// Empty set, should not intersect
	assert(!rs.hasIntersections(DataRange(0, 10)));

	rs += DataRange(10, 20);
	// Full overlap
	assert(rs.hasIntersections(DataRange(10, 20)));
	// Partial overlap left
	assert(rs.hasIntersections(DataRange(5, 15)));
	// Partial overlap right
	assert(rs.hasIntersections(DataRange(15, 25)));
	// Inside
	assert(rs.hasIntersections(DataRange(12, 18)));
	// No overlap before
	assert(!rs.hasIntersections(DataRange(0, 10)));
	// No overlap after
	assert(!rs.hasIntersections(DataRange(20, 30)));
	// Adjacent left
	assert(!rs.hasIntersections(DataRange(0, 10)));
	// Adjacent right
	assert(!rs.hasIntersections(DataRange(20, 25)));

	rs += DataRange(30, 40);
	// Gap between ranges
	assert(!rs.hasIntersections(DataRange(21, 29)));
	// Overlap with second range
	assert(rs.hasIntersections(DataRange(35, 45)));
	// Overlap spanning both ranges
	assert(rs.hasIntersections(DataRange(15, 35)));
}
