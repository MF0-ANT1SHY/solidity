library super {
    function f() public {
    }
}

library this {
    function f() public {
    }
}
library _ {
    function f() public {
    }
}

contract C {
    // These are not errors
    using super for uint;
    using this for uint16;
    using _ for int;
}
// ----
// Warning 6335: (0-49): "super" will be promoted to reserved keyword in the next breaking version and will not be allowed as an identifier anymore.
// Warning 6335: (51-99): "this" will be promoted to reserved keyword in the next breaking version and will not be allowed as an identifier anymore.
// DeclarationError 3726: (0-49): The name "super" is reserved.
// DeclarationError 3726: (51-99): The name "this" is reserved.
// DeclarationError 3726: (100-145): The name "_" is reserved.
// Warning 2319: (0-49): This declaration shadows a builtin symbol.
// Warning 2319: (51-99): This declaration shadows a builtin symbol.
