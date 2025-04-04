contract C {
    function getArray() internal pure returns (uint64[40][1] storage _x) {
        assembly {
            _x.slot := sub(0, 5)
        }
    }

    function fillArray() public {
        uint64[40][1] storage _x = getArray();
        for (uint64 i = 1; i < 40; i++)
            _x[0][i] = i;
    }

    function clearArray() public {
        uint64[40][1] storage _x = getArray();
        delete _x[0];
    }

    function x() public view returns (uint64[40] memory) {
        return getArray()[0];
    }
}
// ----
// x() -> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
// fillArray()
// gas irOptimized: 254227
// gas legacyOptimized: 257258
// x() -> 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27
// clearArray()
// x() -> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
// gas irOptimized: 181920
// gas legacy: 184143
// gas legacyOptimized: 181899
