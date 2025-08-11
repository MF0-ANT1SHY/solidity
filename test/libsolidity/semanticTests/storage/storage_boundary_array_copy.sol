contract C {
	constructor() {
		uint256[10][1] storage _x = getX();
		_x[0] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
	}

	function getX() internal pure returns (uint256[10][1] storage _x) {
		assembly {
			_x.slot := sub(0, 5)
		}
	}

	function getY() internal pure returns (uint256[10][1] storage _y) {
		assembly {
			_y.slot := 5
		}
	}

	function copy_x_to_y() public {
		uint256[10][1] storage _x = getX();
		uint256[10][1] storage _y = getY();
		_y[0] = _x[0];
	}

	function x() public view returns (uint256[10] memory) {
		return getX()[0];
	}

	function y() public view returns (uint256[10] memory) {
		return getY()[0];
	}
}
// ----
// x() -> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
// y() -> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
// copy_x_to_y()
// gas irOptimized: 266114
// x() -> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
// y() -> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
