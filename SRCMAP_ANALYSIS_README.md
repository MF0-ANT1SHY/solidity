# Source Mapping (srcmap) Debug Info Workflow - Analysis Documentation

This directory contains comprehensive documentation analyzing the complete workflow for creating source mapping (srcmap) debug information in the Solidity compiler.

## 📚 Documentation Files

### 1. **Comprehensive Analysis** (Main Documentation)
**File:** [`docs/internals/srcmap_workflow_analysis.rst`](docs/internals/srcmap_workflow_analysis.rst)

The primary, in-depth documentation covering:
- Complete 7-stage workflow from source code to output
- Detailed component analysis with file paths
- Input/Output specifications for each stage
- Source mapping format and compression algorithm
- Data structures and their relationships
- Both compilation paths (Legacy and IR/Yul)
- Special cases and edge conditions
- Testing infrastructure
- External tool integration

**Best for:** Deep understanding, reference documentation, maintainers

### 2. **Quick Reference Summary**
**File:** [`SRCMAP_WORKFLOW_SUMMARY.md`](SRCMAP_WORKFLOW_SUMMARY.md)

Condensed reference guide containing:
- Stage-by-stage workflow overview
- Key components table
- Source mapping format with examples
- Critical data structures
- Key functions reference
- Testing and use cases

**Best for:** Quick lookups, developers, contributors

### 3. **Visual Workflow Diagram**
**File:** [`docs/internals/srcmap_workflow_diagram.txt`](docs/internals/srcmap_workflow_diagram.txt)

ASCII art diagrams showing:
- Visual flow through all 7 stages
- Data structure layouts
- Compression examples with calculations
- Special cases illustrations
- JSON output format examples

**Best for:** Visual learners, presentations, understanding flow

### 4. **Original Format Specification**
**File:** [`docs/internals/source_mappings.rst`](docs/internals/source_mappings.rst)

Existing documentation covering:
- Source mapping format specification
- AST source mappings
- Bytecode source mappings
- Compression rules

**Best for:** Format specification, integration with external tools

## 🗺️ Workflow Overview

```
Solidity Source (.sol)
    ↓
[Parser] → AST with SourceLocation
    ↓
Code Generation (Legacy or IR Path)
    ↓
Assembly Items with DebugData
    ↓
Assembly to Bytecode
    ↓
computeSourceMapping()
    ↓
Compressed "s:l:f:j:m" String
    ↓
JSON Output with sourceMap fields
```

## 🔑 Key Concepts

### Source Mapping Format
```
s:l:f:j:m
```
- **s**: Start byte offset in source
- **l**: Length in bytes
- **f**: Source file index
- **j**: Jump type ('i'=into, 'o'=out, '-'=regular)
- **m**: Modifier depth

### Compression Example
**Uncompressed:** `1:2:1:-:0;1:9:1:-:0;2:1:2:-:0`  
**Compressed:** `1:2:1;:9;2:1:2;;` (28% space savings)

## 📂 Key Components & Files

| Component | Files | Purpose |
|-----------|-------|---------|
| **CompilerStack** | `libsolidity/interface/CompilerStack.{h,cpp}` | Orchestrates compilation |
| **IRGenerator** | `libsolidity/codegen/ir/IRGenerator.{h,cpp}` | Generates Yul IR |
| **EVMCodeTransform** | `libyul/backends/evm/EVMCodeTransform.{h,cpp}` | Converts Yul to assembly |
| **Assembly** | `libevmasm/Assembly.{h,cpp}` | Manages assembly items |
| **AssemblyItem** | `libevmasm/AssemblyItem.{h,cpp}` | Instruction + debug data |
| **computeSourceMapping** | `libevmasm/AssemblyItem.cpp:541` | Generates srcmap string |

## 🎯 Use Cases

Source mappings are essential for:
- **Debuggers**: Remix, Hardhat, Truffle debuggers
- **Coverage Tools**: Measuring test coverage
- **Static Analyzers**: Mapping vulnerabilities to source
- **Profilers**: Identifying gas-heavy code sections

## 🧪 Testing

Test coverage in:
- `test/libevmasm/Assembler.cpp`
- `test/libevmasm/EVMAssemblyTest.cpp`
- `test/libyul/ObjectCompilerTest.cpp`

## 📖 How to Use This Documentation

### For Quick Answers
→ Start with [`SRCMAP_WORKFLOW_SUMMARY.md`](SRCMAP_WORKFLOW_SUMMARY.md)

### For Visual Understanding
→ Check [`docs/internals/srcmap_workflow_diagram.txt`](docs/internals/srcmap_workflow_diagram.txt)

### For Deep Understanding
→ Read [`docs/internals/srcmap_workflow_analysis.rst`](docs/internals/srcmap_workflow_analysis.rst)

### For Format Integration
→ Reference [`docs/internals/source_mappings.rst`](docs/internals/source_mappings.rst)

## 🔗 Related Documentation

- **Compiler Usage:** `docs/using-the-compiler.rst`
- **Optimizer:** `docs/internals/optimizer.rst`
- **IR Breaking Changes:** `docs/ir-breaking-changes.rst`

## 📊 Statistics

- **Total Documentation:** 1,352+ lines
- **Workflow Stages:** 7 detailed stages
- **Components Analyzed:** 15+ key components
- **Formats:** RST, Markdown, ASCII diagrams
- **Coverage:** Complete input/output analysis

## 🤝 Contributing

When contributing to source mapping functionality:

1. Preserve `SourceLocation` through all compilation stages
2. Update `Assembly::setSourceLocation()` before emitting instructions
3. Ensure optimizers maintain debug information
4. Add tests to verify source mapping accuracy
5. Update this documentation for significant changes

## 📝 License

This documentation follows the same GPL-3.0 license as the Solidity project.

---

**Created:** 2025-10-09  
**Purpose:** Comprehensive analysis of srcmap debug info workflow  
**Maintainer:** Solidity Team
