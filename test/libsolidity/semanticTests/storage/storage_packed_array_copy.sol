contract C {
    bytes8[9] _x; // 4 per slot
    bytes17[10] _y; // 1 per slot, no offset counter

	constructor() {
        for (uint256 i = 0; i < _x.length; ++i) _x[i] = bytes8(uint64(i));
        _y[8] = _y[9] = bytes8(uint64(2));
	}

    function f()
        public
        returns (bytes17 a, bytes17 b, bytes17 c, bytes17 d, bytes17 e)
    {
        _y = _x;
        a = _y[1];
        b = _y[2];
        c = _y[3];
        d = _y[4];
        e = _y[9];
    }
}

// ----
// f() -> 0x01000000000000000000000000000000000000000000000000, 0x02000000000000000000000000000000000000000000000000, 0x03000000000000000000000000000000000000000000000000, 0x04000000000000000000000000000000000000000000000000, 0x00
// gas irOptimized: 191520
// gas legacy: 199338

