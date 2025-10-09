.. index:: srcmap workflow analysis

*********************************************
Source Mapping (srcmap) Debug Info Workflow
*********************************************

Overview
========

This document provides a comprehensive analysis of the source mapping (srcmap) debug info 
workflow in the Solidity compiler. Source mappings allow debuggers and analysis tools to 
map bytecode instructions back to their original source code locations.

The workflow consists of several stages, from parsing source code through AST generation, 
code generation, assembly, and finally producing the srcmap string that maps bytecode 
positions to source locations.

Workflow Architecture
=====================

The source mapping workflow involves the following major components:

1. **Source Code Parsing & AST Generation**
2. **Source Location Tracking**
3. **Code Generation (Solidity or IR/Yul)**
4. **Assembly Item Generation**
5. **Source Mapping Computation**
6. **Output Generation**

Detailed Workflow Analysis
===========================

Stage 1: Source Code Parsing & AST Generation
----------------------------------------------

**Components:**
  - ``CompilerStack`` (``libsolidity/interface/CompilerStack.h``, ``.cpp``)
  - ``Parser`` (parses source code)
  - ``AST Nodes`` (``libsolidity/ast/AST.h``)

**Input:**
  - Solidity source code files (.sol)
  - Source file names and content

**Process:**
  1. Source code is read and parsed into an Abstract Syntax Tree (AST)
  2. Each AST node stores its ``SourceLocation`` containing:
     - ``start``: byte offset from beginning of source file
     - ``end``: byte offset to end of source range
     - ``sourceName``: shared pointer to source file name
  3. Source files are assigned unique integer identifiers (indices)

**Output:**
  - AST with source location information attached to each node
  - Mapping of source file names to integer indices (via ``CompilerStack::sourceIndices()``)

**Key Data Structures:**

.. code-block:: cpp

    struct SourceLocation
    {
        int start;                                    // byte offset to start
        int end;                                      // byte offset to end
        std::shared_ptr<std::string const> sourceName; // source file name
    };

Stage 2: Source Location Tracking
----------------------------------

**Components:**
  - ``DebugData`` (``liblangutil/DebugData.h``)
  - ``SourceLocation`` (``liblangutil/SourceLocation.h``)

**Input:**
  - AST nodes with attached source locations

**Process:**
  1. During code generation, source locations are tracked and propagated
  2. ``DebugData`` structure stores:
     - ``nativeLocation``: Location in Yul code (for IR pipeline)
     - ``originLocation``: Location in original Solidity source
     - ``astID``: Optional AST node ID
  3. For Yul/IR backend: IR generator preserves origin locations from Solidity AST

**Output:**
  - Debug data attached to intermediate representations
  - Source location context maintained throughout compilation

**Key Data Structures:**

.. code-block:: cpp

    struct DebugData
    {
        langutil::SourceLocation nativeLocation;  // Location in Yul
        langutil::SourceLocation originLocation;  // Location in original source
        std::optional<int64_t> astID;            // AST node ID
    };

Stage 3: Code Generation
-------------------------

Two compilation paths exist:

Path A: Direct Solidity to EVM (Legacy)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Components:**
  - ``Compiler`` (``libsolidity/codegen/Compiler.h``, ``.cpp``)
  - ``ContractCompiler`` (``libsolidity/codegen/ContractCompiler.h``, ``.cpp``)
  - ``ExpressionCompiler`` (``libsolidity/codegen/ExpressionCompiler.h``, ``.cpp``)
  - ``CompilerContext`` (``libsolidity/codegen/CompilerContext.h``, ``.cpp``)

**Input:**
  - AST nodes with source locations
  - Compiler settings and optimization flags

**Process:**
  1. ``Compiler::compileContract()`` orchestrates the compilation
  2. ``CompilerContext`` maintains:
     - Active Assembly object
     - Current source location via ``m_visitedNodes`` stack
  3. As each AST node is visited:
     - ``CompilerContext::setSourceLocation()`` is called
     - Assembly's current source location is updated via ``Assembly::setSourceLocation()``
  4. When emitting assembly instructions:
     - Instructions inherit the current source location
     - Source location stored in ``AssemblyItem::m_debugData``

**Output:**
  - ``Assembly`` objects containing ``AssemblyItem`` sequences
  - Each ``AssemblyItem`` has attached ``DebugData`` with source location

Path B: IR/Yul Pipeline (Modern)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Components:**
  - ``IRGenerator`` (``libsolidity/codegen/ir/IRGenerator.h``, ``.cpp``)
  - ``IRGeneratorForStatements`` (``libsolidity/codegen/ir/IRGeneratorForStatements.h``, ``.cpp``)
  - ``YulStack`` (``libyul/YulStack.h``, ``.cpp``)
  - ``EVMCodeTransform`` (``libyul/backends/evm/EVMCodeTransform.h``, ``.cpp``)

**Input:**
  - AST nodes with source locations
  - Optimization settings
  - Debug info selection flags

**Process:**
  1. ``IRGenerator::run()`` generates Yul IR from Solidity AST
     - Yul statements annotated with origin locations from Solidity
  2. Yul optimizer (optional) preserves debug information
  3. ``EVMCodeTransform`` converts Yul to EVM assembly:
     - Calls ``m_assembly.setSourceLocation()`` before each operation
     - Uses ``originLocationOf()`` to extract source location from Yul nodes
  4. Assembly items created with source location in ``DebugData``

**Output:**
  - ``Assembly`` objects with ``AssemblyItem`` sequences
  - Source locations track back to original Solidity source (via ``originLocation``)

Stage 4: Assembly Item Generation
----------------------------------

**Components:**
  - ``Assembly`` (``libevmasm/Assembly.h``, ``.cpp``)
  - ``AssemblyItem`` (``libevmasm/AssemblyItem.h``, ``.cpp``)

**Input:**
  - High-level operations (from Compiler or EVMCodeTransform)
  - Current source location context

**Process:**
  1. ``Assembly`` maintains ``m_currentSourceLocation``
  2. When items are appended via ``Assembly::append()``:
     - ``AssemblyItem`` is created with current source location
     - Additional metadata stored:
       - ``m_modifierDepth``: Modifier nesting depth (for Solidity modifiers)
       - Jump type: IntoFunction, OutOfFunction, or Ordinary
  3. Assembly optimization stages preserve debug information:
     - Inliner, peephole optimizer, CSE, etc. maintain source locations

**Output:**
  - Sequence of ``AssemblyItem`` objects in ``Assembly::m_codeSections``
  - Each item contains:
     - Operation type (instruction, push, tag, etc.)
     - Source location in ``m_debugData``
     - Modifier depth
     - Jump type

**Key Data Structures:**

.. code-block:: cpp

    class AssemblyItem
    {
        AssemblyItemType m_type;                  // Operation, Push, Tag, etc.
        langutil::DebugData::ConstPtr m_debugData; // Source location & debug info
        size_t m_modifierDepth;                   // Modifier nesting level
        JumpType m_jumpType;                      // Jump classification
        // ... other fields
    };

Stage 5: Assembly to Bytecode
------------------------------

**Components:**
  - ``Assembly::assemble()`` (``libevmasm/Assembly.cpp``)
  - ``LinkerObject`` (``libevmasm/LinkerObject.h``)

**Input:**
  - ``Assembly`` object with ``AssemblyItem`` sequences

**Process:**
  1. ``Assembly::assemble()`` or ``Assembly::assembleEOF()`` is called
  2. Assembly items are converted to bytecode:
     - Each instruction generates one or more bytes
     - Some items (Push, Tag) expand to multiple bytes
  3. Bytecode addresses calculated for each item
  4. Tag positions resolved and jump destinations updated

**Output:**
  - ``LinkerObject`` containing:
     - Raw bytecode (``bytecode`` field)
     - Link references for libraries
     - Immutable references
  - Assembly items remain available for source mapping generation

Stage 6: Source Mapping Computation
------------------------------------

**Components:**
  - ``AssemblyItem::computeSourceMapping()`` (``libevmasm/AssemblyItem.cpp``)
  - ``EVMAssemblyStack::assemble()`` (``libevmasm/EVMAssemblyStack.cpp``)
  - ``CompilerStack::sourceMapping()`` / ``CompilerStack::runtimeSourceMapping()``

**Input:**
  - Sequence of ``AssemblyItem`` objects (from ``Assembly::m_codeSections[].items``)
  - Map of source file names to integer indices

**Process:**
  1. ``AssemblyItem::computeSourceMapping()`` iterates through assembly items
  2. For each item, extracts from ``DebugData``:
     - ``location.start``: byte offset in source (s)
     - ``location.end``: end offset (used to compute length l)
     - Source file index from name lookup (f)
     - Jump type: 'i' (into), 'o' (out), or '-' (regular) (j)
     - Modifier depth (m)
  3. Applies compression rules:
     - Omit field if same as previous item
     - Omit trailing fields if unchanged
     - Results in format: ``s:l:f:j:m``
  4. Multiple items for multi-byte instructions handled via ``opcodeCount()``
  5. Items concatenated with semicolon separators

**Output:**
  - Compressed source mapping string (e.g., ``"0:23:0:-:0;5:18:0;;"``)
  - One entry per instruction (not per byte)
  - Stored in contract metadata

**Algorithm Details:**

The compression algorithm works as follows:

.. code-block:: text

    For each AssemblyItem:
        length = end - start
        sourceIndex = lookup(sourceName)
        jump = determine_jump_type(item)
        modifierDepth = item.modifierDepth
        
        // Determine which fields changed
        components = 5
        if modifierDepth == prev_modifierDepth: components--
        if jump == prev_jump: components--
        if sourceIndex == prev_sourceIndex: components--
        if length == prev_length: components--
        if start == prev_start: components--
        
        // Output only changed fields
        output fields based on components count
        
        // Handle multi-byte instructions
        if item.opcodeCount() > 1:
            append (opcodeCount - 1) semicolons

**Source Mapping Format:**

``s:l:f:j:m;s:l:f:j:m;...``

Where:
  - ``s``: Start byte offset in source file
  - ``l``: Length in bytes  
  - ``f``: Source file index (from sourceIndices map)
  - ``j``: Jump type ('i'=into function, 'o'=out of function, '-'=regular)
  - ``m``: Modifier depth (nesting level)

Compression rules:
  - Empty field inherits value from previous element
  - Missing ``:`` means all following fields are empty

Example:
  - Uncompressed: ``1:2:1:-:0;1:9:1:-:0;2:1:2:-:0;2:1:2:-:0``
  - Compressed: ``1:2:1;:9;2:1:2;;``

Stage 7: Output Integration
----------------------------

**Components:**
  - ``CompilerStack`` (``libsolidity/interface/CompilerStack.h``)
  - ``StandardCompiler`` (``libsolidity/interface/StandardCompiler.cpp``)
  - ``EVMAssemblyStack`` (``libevmasm/EVMAssemblyStack.h``)

**Input:**
  - Compiled contract with bytecode and assembly
  - Source mapping strings

**Process:**
  1. Source mappings computed lazily when requested:
     - ``CompilerStack::sourceMapping()`` for deployment code
     - ``CompilerStack::runtimeSourceMapping()`` for runtime code
  2. For standard JSON interface:
     - Included in contract output under ``evm.bytecode.sourceMap``
     - Runtime mapping under ``evm.deployedBytecode.sourceMap``
  3. Also included in assembly JSON output

**Output:**
  - JSON output containing:
    - ``contracts[file][contract].evm.bytecode.sourceMap``
    - ``contracts[file][contract].evm.deployedBytecode.sourceMap``
    - ``contracts[file][contract].evm.bytecode.object`` (hex bytecode)
  - Assembly string output (human-readable, optional)

Complete Workflow Diagram
==========================

.. code-block:: text

    Solidity Source (.sol)
           |
           v
    [Parser] --> AST with SourceLocation
           |
           +--> AST Node (start, end, sourceName)
           |
           v
    +-----------------+------------------+
    | Legacy Pipeline |   IR Pipeline    |
    +-----------------+------------------+
           |                  |
           v                  v
    [ContractCompiler]  [IRGenerator]
           |                  |
           v                  v
    [CompilerContext]    [Yul AST]
           |                  |
           +--setSourceLocation()
           |                  |
           v                  v
    [Assembly.append()] [EVMCodeTransform]
           |                  |
           +--setSourceLocation()
           |                  |
           +------------------+
                    |
                    v
         Assembly with AssemblyItems
         (each has DebugData with SourceLocation)
                    |
                    v
         [Assembly::assemble()]
                    |
         +----------+----------+
         |                     |
         v                     v
    Bytecode              AssemblyItems
    (LinkerObject)        (preserved)
         |                     |
         +----------+----------+
                    |
                    v
    [AssemblyItem::computeSourceMapping()]
              (items, sourceIndices)
                    |
                    v
         Source Mapping String
         "s:l:f:j:m;s:l:f:j:m;..."
                    |
                    v
         [CompilerStack Output]
                    |
         +----------+----------+
         |                     |
         v                     v
    JSON Output          CLI Output
    (sourceMap field)    (assembly text)

Component Summary Table
=======================

+---------------------------+--------------------------------------------+-----------------------------------+
| Component                 | Primary Files                              | Responsibility                    |
+===========================+============================================+===================================+
| **CompilerStack**         | libsolidity/interface/                     | Orchestrates compilation,         |
|                           | CompilerStack.{h,cpp}                      | manages contracts, provides API   |
+---------------------------+--------------------------------------------+-----------------------------------+
| **Parser**                | libsolidity/parsing/                       | Parses Solidity into AST          |
+---------------------------+--------------------------------------------+-----------------------------------+
| **AST Nodes**             | libsolidity/ast/AST.h                      | Represent parsed code with        |
|                           |                                            | SourceLocation                    |
+---------------------------+--------------------------------------------+-----------------------------------+
| **SourceLocation**        | liblangutil/SourceLocation.{h,cpp}         | Stores source position (start,    |
|                           |                                            | end, sourceName)                  |
+---------------------------+--------------------------------------------+-----------------------------------+
| **DebugData**             | liblangutil/DebugData.h                    | Wraps source locations with       |
|                           |                                            | additional debug info             |
+---------------------------+--------------------------------------------+-----------------------------------+
| **Compiler (Legacy)**     | libsolidity/codegen/                       | Compiles Solidity AST directly    |
|                           | Compiler.{h,cpp}                           | to EVM assembly                   |
+---------------------------+--------------------------------------------+-----------------------------------+
| **ContractCompiler**      | libsolidity/codegen/                       | Compiles contract-level           |
|                           | ContractCompiler.{h,cpp}                   | constructs                        |
+---------------------------+--------------------------------------------+-----------------------------------+
| **ExpressionCompiler**    | libsolidity/codegen/                       | Compiles expressions to assembly  |
|                           | ExpressionCompiler.{h,cpp}                 |                                   |
+---------------------------+--------------------------------------------+-----------------------------------+
| **CompilerContext**       | libsolidity/codegen/                       | Maintains compilation state,      |
|                           | CompilerContext.{h,cpp}                    | tracks source locations           |
+---------------------------+--------------------------------------------+-----------------------------------+
| **IRGenerator**           | libsolidity/codegen/ir/                    | Generates Yul IR from Solidity    |
|                           | IRGenerator.{h,cpp}                        | AST                               |
+---------------------------+--------------------------------------------+-----------------------------------+
| **YulStack**              | libyul/YulStack.{h,cpp}                    | Compiles Yul code to assembly     |
+---------------------------+--------------------------------------------+-----------------------------------+
| **EVMCodeTransform**      | libyul/backends/evm/                       | Transforms Yul to EVM assembly    |
|                           | EVMCodeTransform.{h,cpp}                   | with source tracking              |
+---------------------------+--------------------------------------------+-----------------------------------+
| **Assembly**              | libevmasm/Assembly.{h,cpp}                 | Manages assembly items, provides  |
|                           |                                            | assemble() function               |
+---------------------------+--------------------------------------------+-----------------------------------+
| **AssemblyItem**          | libevmasm/AssemblyItem.{h,cpp}             | Represents single assembly        |
|                           |                                            | instruction with debug data       |
+---------------------------+--------------------------------------------+-----------------------------------+
| **computeSourceMapping** | libevmasm/AssemblyItem.cpp                 | Static function that generates    |
|                           | (line 541)                                 | compressed srcmap string          |
+---------------------------+--------------------------------------------+-----------------------------------+
| **EVMAssemblyStack**      | libevmasm/EVMAssemblyStack.{h,cpp}         | Standalone assembly stack,        |
|                           |                                            | calls computeSourceMapping        |
+---------------------------+--------------------------------------------+-----------------------------------+
| **LinkerObject**          | libevmasm/LinkerObject.{h,cpp}             | Contains final bytecode with      |
|                           |                                            | link references                   |
+---------------------------+--------------------------------------------+-----------------------------------+
| **StandardCompiler**      | libsolidity/interface/                     | Implements Standard JSON API      |
|                           | StandardCompiler.cpp                       |                                   |
+---------------------------+--------------------------------------------+-----------------------------------+

Data Flow Summary
=================

Source Location Propagation
----------------------------

1. **AST Level**: Each AST node stores ``SourceLocation`` from parser
2. **Code Generation**: 
   - Legacy: ``CompilerContext`` calls ``Assembly::setSourceLocation()`` before emitting
   - IR: ``EVMCodeTransform`` calls ``m_assembly.setSourceLocation()`` before each Yul operation
3. **Assembly Level**: ``Assembly::m_currentSourceLocation`` stored in new ``AssemblyItem::m_debugData``
4. **Source Mapping**: ``AssemblyItem::computeSourceMapping()`` extracts locations from items

Key Entry Points
----------------

For direct compilation:
  - ``CompilerStack::compileContract()`` → ``Compiler::compileContract()``
  - ``CompilerStack::sourceMapping()`` → ``AssemblyItem::computeSourceMapping()``

For IR compilation:
  - ``CompilerStack::generateIR()`` → ``IRGenerator::run()``
  - ``CompilerStack::compileYul()`` → ``YulStack::assemble()``
  - ``YulStack::assemble()`` → ``AssemblyItem::computeSourceMapping()``

Important Functions
===================

Source Location Management
--------------------------

- ``Assembly::setSourceLocation(SourceLocation const&)``
  - Updates ``m_currentSourceLocation``
  - Called before appending assembly items

- ``Assembly::append(AssemblyItem)``
  - Creates items with current source location
  - Returns reference to appended item

Source Mapping Generation
--------------------------

- ``AssemblyItem::computeSourceMapping(AssemblyItems const&, map<string, unsigned> const&)``
  - **Location**: ``libevmasm/AssemblyItem.cpp:541``
  - **Returns**: Compressed source mapping string
  - **Algorithm**: 
    1. Iterate through all assembly items
    2. Extract source location components (s, l, f, j, m)
    3. Compare with previous values
    4. Emit only changed components
    5. Handle multi-byte instructions

- ``CompilerStack::sourceMapping(string const&)``
  - Lazy computation of source mapping for deployment code
  - Calls ``computeSourceMapping()`` on assembly items
  
- ``CompilerStack::runtimeSourceMapping(string const&)``
  - Lazy computation for runtime code
  - Separate mapping from deployment code

Configuration and Optimization
===============================

Debug Info Selection
--------------------

**Component**: ``DebugInfoSelection`` (``liblangutil/DebugInfoSelection.h``)

Controls which debug information is included:
  - Source locations
  - AST IDs  
  - Source code snippets in assembly output

Affects assembly string output but not binary source mapping generation.

Optimization Impact
-------------------

Assembly optimizers preserve source locations:
  - **Peephole Optimizer**: Maintains locations when replacing instruction sequences
  - **Common Subexpression Eliminator**: Preserves debug data
  - **Deduplicate**: Keeps source locations on deduplicated blocks
  - **Inliner**: Propagates locations from inlined code

Modifier Depth Tracking
========================

**Purpose**: Track nesting level in Solidity modifiers for debugging

**Mechanism**:
  1. ``Assembly::m_currentModifierDepth`` incremented when entering modifier placeholder
  2. Stored in ``AssemblyItem::m_modifierDepth``
  3. Included as 'm' field in source mapping
  4. Allows debuggers to distinguish same modifier used multiple times

Jump Type Classification
========================

**Purpose**: Help debuggers understand control flow

**Types**:
  - ``IntoFunction`` ('i'): Call into function
  - ``OutOfFunction`` ('o'): Return from function  
  - ``Ordinary`` ('-'): Regular jump (loop, conditional)

**Detection**:
  - Set by compiler during code generation
  - Based on AST node type (FunctionCall, Return, etc.)
  - For IR/Yul: Based on Yul operation type

Special Cases
=============

Internal Source Files
---------------------

Compiler-generated utility functions (e.g., ABI encoding) have special handling:
  - Assigned synthetic source names (e.g., "#utility.yul")
  - Included in ``generatedSources`` output
  - Have their own source indices

Library Linking
---------------

``PushLibraryAddress`` items have no source mapping until linking time.
Preserved through compilation for later resolution.

Immutables
----------

``PushImmutable`` and ``AssignImmutable`` items:
  - Track source location of immutable declaration
  - Bytecode positions recorded for constructor patching

Verbatim Bytecode
-----------------

Yul ``verbatim`` builtin:
  - Treated as single instruction
  - Source mapping may be inaccurate (documented limitation)

EOF (EVM Object Format)
-----------------------

For EOF contracts:
  - Multiple code sections supported
  - Each section has independent source mapping
  - Concatenated in output

Testing and Validation
=======================

Test Infrastructure
-------------------

**Files**: 
  - ``test/libevmasm/Assembler.cpp``
  - ``test/libevmasm/EVMAssemblyTest.cpp``
  - ``test/libyul/ObjectCompilerTest.cpp``

**Coverage**:
  - Source mapping compression
  - Jump type detection
  - Modifier depth tracking
  - Multi-byte instruction handling

External Tools
--------------

Source mappings used by:
  - **Debuggers**: Remix, Hardhat, Truffle
  - **Coverage tools**: Measure test coverage
  - **Static analyzers**: Map vulnerabilities to source
  - **Profilers**: Identify gas-heavy code

References
==========

Documentation
-------------

- ``docs/internals/source_mappings.rst`` - Source mapping format specification
- ``docs/using-the-compiler.rst`` - Compiler output documentation

Key Source Files
----------------

Core Implementation:
  - ``libevmasm/AssemblyItem.cpp:541`` - ``computeSourceMapping()``
  - ``libevmasm/Assembly.cpp`` - Assembly management
  - ``libevmasm/EVMAssemblyStack.cpp`` - High-level assembly interface
  - ``libsolidity/interface/CompilerStack.cpp`` - Compilation orchestration

IR Pipeline:
  - ``libsolidity/codegen/ir/IRGenerator.cpp`` - IR generation
  - ``libyul/backends/evm/EVMCodeTransform.cpp`` - Yul to EVM
  - ``libyul/YulStack.cpp`` - Yul compilation

Data Structures:
  - ``liblangutil/SourceLocation.h`` - Source position tracking
  - ``liblangutil/DebugData.h`` - Debug information wrapper
  - ``libevmasm/AssemblyItem.h`` - Assembly instruction representation

Conclusion
==========

The source mapping workflow in Solidity is a sophisticated system that:

1. **Preserves** source location information from parsing through to bytecode generation
2. **Tracks** additional metadata (jump types, modifier depth) for enhanced debugging
3. **Compresses** the mapping data efficiently using delta encoding
4. **Supports** both direct compilation and IR-based compilation pipelines
5. **Maintains** accuracy through optimization passes

The resulting source maps enable powerful debugging and analysis tools, making smart 
contract development safer and more efficient.
