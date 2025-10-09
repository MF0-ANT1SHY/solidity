# Source Mapping (srcmap) Debug Info Workflow - Summary

This is a quick reference summary of the comprehensive analysis found in `docs/internals/srcmap_workflow_analysis.rst`.

## Overview

Source mappings allow debuggers and analysis tools to map EVM bytecode instructions back to their original Solidity source code locations. The workflow preserves location information from parsing through to final bytecode generation.

## Workflow Stages

### 1. Source Code Parsing & AST Generation
- **Components**: `CompilerStack`, `Parser`, AST Nodes
- **Input**: Solidity source files (.sol)
- **Output**: AST with `SourceLocation` (start, end, sourceName) on each node
- **Key Files**: `libsolidity/interface/CompilerStack.{h,cpp}`, `libsolidity/ast/AST.h`

### 2. Source Location Tracking
- **Components**: `DebugData`, `SourceLocation`
- **Input**: AST nodes with source locations
- **Output**: Debug data propagated through compilation
- **Key Files**: `liblangutil/DebugData.h`, `liblangutil/SourceLocation.h`

### 3. Code Generation (Two Paths)

#### Path A: Direct Solidity to EVM (Legacy)
- **Components**: `Compiler`, `ContractCompiler`, `ExpressionCompiler`, `CompilerContext`
- **Process**: Directly compiles AST to EVM assembly, tracking source locations
- **Key Files**: `libsolidity/codegen/*.{h,cpp}`

#### Path B: IR/Yul Pipeline (Modern)
- **Components**: `IRGenerator`, `YulStack`, `EVMCodeTransform`
- **Process**: AST → Yul IR → Optimized Yul → EVM Assembly
- **Key Files**: `libsolidity/codegen/ir/IRGenerator.{h,cpp}`, `libyul/backends/evm/EVMCodeTransform.{h,cpp}`

### 4. Assembly Item Generation
- **Components**: `Assembly`, `AssemblyItem`
- **Input**: High-level operations with source locations
- **Output**: Sequence of `AssemblyItem` objects with `DebugData`
- **Key Files**: `libevmasm/Assembly.{h,cpp}`, `libevmasm/AssemblyItem.{h,cpp}`

### 5. Assembly to Bytecode
- **Components**: `Assembly::assemble()`, `LinkerObject`
- **Input**: Assembly items
- **Output**: Raw bytecode, assembly items preserved for mapping
- **Key Files**: `libevmasm/Assembly.cpp`

### 6. Source Mapping Computation
- **Components**: `AssemblyItem::computeSourceMapping()`
- **Input**: Assembly items + source indices map
- **Output**: Compressed source mapping string `"s:l:f:j:m;s:l:f:j:m;..."`
- **Key Files**: `libevmasm/AssemblyItem.cpp:541`

### 7. Output Integration
- **Components**: `CompilerStack`, `StandardCompiler`
- **Output**: JSON with `sourceMap` fields
- **Access**: `contracts[file][contract].evm.bytecode.sourceMap`

## Source Mapping Format

Format: `s:l:f:j:m` separated by `;`

- **s**: Start byte offset in source file
- **l**: Length in bytes
- **f**: Source file index
- **j**: Jump type ('i'=into, 'o'=out, '-'=regular)
- **m**: Modifier depth (nesting level)

### Compression Rules
- Empty field inherits from previous entry
- Missing `:` means all following fields empty

Example:
- Uncompressed: `1:2:1:-:0;1:9:1:-:0;2:1:2:-:0`
- Compressed: `1:2:1;:9;2:1:2;;`

## Key Functions

- `Assembly::setSourceLocation(SourceLocation const&)` - Updates current location context
- `Assembly::append(AssemblyItem)` - Creates items with current location
- `AssemblyItem::computeSourceMapping(items, sourceIndices)` - Generates srcmap string
- `CompilerStack::sourceMapping(contractName)` - Returns deployment code mapping
- `CompilerStack::runtimeSourceMapping(contractName)` - Returns runtime code mapping

## Critical Data Structures

```cpp
struct SourceLocation {
    int start;                                    // byte offset
    int end;                                      // end offset
    std::shared_ptr<std::string const> sourceName; // file name
};

struct DebugData {
    langutil::SourceLocation nativeLocation;  // Yul location
    langutil::SourceLocation originLocation;  // Solidity location
    std::optional<int64_t> astID;            // AST node ID
};

class AssemblyItem {
    AssemblyItemType m_type;
    langutil::DebugData::ConstPtr m_debugData;
    size_t m_modifierDepth;
    JumpType m_jumpType;
};
```

## Component Reference Table

| Component | Primary Files | Responsibility |
|-----------|---------------|----------------|
| CompilerStack | libsolidity/interface/CompilerStack.{h,cpp} | Compilation orchestration |
| IRGenerator | libsolidity/codegen/ir/IRGenerator.{h,cpp} | Solidity to Yul IR |
| EVMCodeTransform | libyul/backends/evm/EVMCodeTransform.{h,cpp} | Yul to EVM assembly |
| Assembly | libevmasm/Assembly.{h,cpp} | Assembly management |
| AssemblyItem | libevmasm/AssemblyItem.{h,cpp} | Assembly instruction + debug data |
| computeSourceMapping | libevmasm/AssemblyItem.cpp:541 | Generates srcmap string |

## Testing

Test files:
- `test/libevmasm/Assembler.cpp`
- `test/libevmasm/EVMAssemblyTest.cpp`
- `test/libyul/ObjectCompilerTest.cpp`

## Use Cases

Source mappings are used by:
- **Debuggers**: Remix, Hardhat, Truffle
- **Coverage tools**: Measure test coverage
- **Static analyzers**: Map vulnerabilities to source
- **Profilers**: Identify gas-heavy code

## References

- Full documentation: `docs/internals/srcmap_workflow_analysis.rst`
- Format specification: `docs/internals/source_mappings.rst`
- Compiler usage: `docs/using-the-compiler.rst`

## Key Insights

1. Source locations propagate from AST through all compilation stages
2. Two compilation paths (Legacy and IR) both preserve source info
3. Compression reduces mapping size significantly
4. Optimizers maintain source location accuracy
5. Jump types and modifier depth enable advanced debugging
