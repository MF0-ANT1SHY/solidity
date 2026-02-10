.. index:: compilation pipeline, compiler internals
.. _compilation-pipeline:

********************
Compilation Pipeline
********************

This document breaks down the Solidity compiler pipeline following the classic compiler
stages (lexing, parsing, AST, IR, optimization, and bytecode generation) and highlights
the concrete data models and source locations used in the Solidity codebase.

Overview in CompilerStack
=========================

``libsolidity/interface/CompilerStack.{h,cpp}`` exposes the end-to-end pipeline. The
``CompilerStack::State`` enum captures the coarse stages:

* ``Empty`` -> ``SourcesSet``: sources are loaded into ``CompilerStack::Source``.
* ``SourcesSet`` -> ``Parsed``: parsing produces the Solidity AST.
* ``Parsed`` -> ``ParsedAndImported``: import resolution expands the source graph.
* ``ParsedAndImported`` -> ``AnalysisPerformed``: semantic analysis annotates the AST.
* ``AnalysisPerformed`` -> ``CompilationSuccessful``: code generation and assembly finish.

Detailed Stage Map (Location + Data Model)
==========================================

.. list-table::
   :header-rows: 1
   :widths: 16 34 25 25

   * - Stage (compiler theory)
     - Primary location in this repository
     - Input data model
     - Output data model
   * - Source loading
     - ``CompilerStack`` and ``CompilerStack::Source`` in
       ``libsolidity/interface/CompilerStack.{h,cpp}``
     - Source strings / file contents
     - ``langutil::CharStream`` stored in
       ``CompilerStack::Source::charStream`` (see ``liblangutil/CharStream.h``)
   * - Lexical analysis (tokenization)
     - ``liblangutil/Scanner.{h,cpp}`` and ``liblangutil/Token.h``
     - ``langutil::CharStream``
     - ``langutil::Token`` stream plus ``langutil::SourceLocation`` metadata
   * - Syntax parsing (AST construction)
     - ``libsolidity/parsing/Parser.{h,cpp}``,
       AST definitions in ``libsolidity/ast/AST.h``
     - Tokens from ``Scanner``
     - ``ASTPointer<SourceUnit>`` (root AST node)
   * - Import resolution
     - ``CompilerStack::resolveImports`` in
       ``libsolidity/interface/CompilerStack.cpp``
     - ``SourceUnit`` AST graph with import directives
     - Expanded source graph in ``CompilerStack::Source`` and
       updated ``SourceUnit`` nodes
   * - Semantic analysis (name/type resolution, checks)
     - ``libsolidity/analysis/`` (e.g. ``NameAndTypeResolver``,
       ``TypeChecker``, ``SyntaxChecker``), ``GlobalContext`` in
       ``libsolidity/analysis/GlobalContext.h``
     - Solidity AST
     - AST annotated via ``ASTAnnotations`` (see
       ``libsolidity/ast/ASTAnnotations.h``) with scopes, types, and
       resolved references
   * - IR generation (Yul)
     - ``libsolidity/codegen/ir/IRGenerator.{h,cpp}``
     - Annotated Solidity AST, metadata, optimizer settings
     - Yul IR text returned by ``IRGenerator::run`` and stored in
       ``CompilerStack::Contract::yulIR`` / ``yulIROptimized`` (``std::string``)
   * - IR optimization (Yul optimizer)
     - ``libyul/optimiser/`` (passes and optimizer pipeline)
     - Yul IR text and Yul AST nodes (``libyul/AST.h``)
     - Optimized Yul IR text (``std::string``)
   * - Legacy code generation (direct EVM)
     - ``libsolidity/codegen/Compiler.{h,cpp}``
     - Annotated Solidity AST
     - ``evmasm::Assembly`` (see ``libevmasm/Assembly.h``)
   * - IR-based EVM lowering
     - ``CompilerStack::generateEVMFromIR`` in
       ``libsolidity/interface/CompilerStack.cpp``
     - Optimized Yul IR
     - ``evmasm::Assembly``
   * - Assembly to bytecode
     - ``CompilerStack::assemble`` and ``evmasm::LinkerObject``
       (``libevmasm/LinkerObject.h``)
     - ``evmasm::Assembly``
     - ``evmasm::LinkerObject`` containing bytecode and link references
   * - Linking + metadata emission
     - ``CompilerStack::link`` and ``CompilerStack::createMetadata`` in
       ``libsolidity/interface/CompilerStack.{h,cpp}``
     - ``evmasm::LinkerObject`` + metadata JSON
     - Linked bytecode with CBOR metadata (``bytes``)

Concrete Example: Counter Contract
==================================

The following minimal contract is used to illustrate how data changes across the
pipeline. The snippets are intentionally short and show representative excerpts.

Source input (Solidity)
-----------------------

.. code-block:: solidity

   // SPDX-License-Identifier: MIT
   pragma solidity ^0.8.20;

   contract Counter {
       uint256 public value;

       function increment() external {
           value += 1;
       }
   }

Lexical analysis output (Scanner tokens)
----------------------------------------

Input: ``langutil::CharStream`` from the source above. Output: a stream of
``langutil::Token`` values (excerpt, pragma tokens omitted).

.. code-block:: text

   Contract "contract"
   Identifier "Counter"
   LBrace "{"
   Identifier "uint256"
   Identifier "value"
   Public "public"
   Function "function"
   Identifier "increment"
   LParen "("
   RParen ")"
   External "external"
   LBrace "{"
   Identifier "value"
   AssignAdd "+="
   Number "1"
   Semicolon ";"
   RBrace "}"
   RBrace "}"

Parsing output (AST)
--------------------

Output: ``ASTPointer<SourceUnit>`` containing the Solidity AST.

.. code-block:: text

   SourceUnit
   └─ ContractDefinition "Counter"
      ├─ VariableDeclaration "value" (type: uint256, visibility: public)
      └─ FunctionDefinition "increment"
         └─ Block
            └─ ExpressionStatement
               └─ Assignment (operator: +=)
                  ├─ Identifier "value"
                  └─ Literal 1

Semantic analysis output (annotated AST)
---------------------------------------

The AST is annotated via ``ASTAnnotations`` with resolved symbols and types:

* ``value`` is resolved to a storage variable of type ``uint256``.
* ``increment`` is resolved as an ``external`` function with no parameters.
* The ``+=`` operator is typed as ``uint256`` arithmetic.

IR generation output (Yul, excerpt)
-----------------------------------

Output: Yul IR text from ``IRGenerator::run`` stored in
``CompilerStack::Contract::yulIR`` (excerpt).

.. code-block:: yul

   object "Counter" {
     code {
       // constructor + deploy logic omitted
     }
     object "Counter_deployed" {
       code {
         // dispatch omitted
         let slot := 0
         sstore(slot, add(sload(slot), 1))
       }
     }
   }

IR optimization output
----------------------

The Yul optimizer rewrites the IR (stored in ``yulIROptimized``), for example
by simplifying arithmetic and removing dead code. The structure remains Yul text.

Legacy / IR-based codegen output (EVM assembly, excerpt)
--------------------------------------------------------

Output: ``evmasm::Assembly`` containing EVM opcodes. For the increment logic,
the assembly excerpt is:

.. code-block:: text

   PUSH1 0x00
   SLOAD
   PUSH1 0x01
   ADD
   PUSH1 0x00
   SSTORE

Bytecode output (linked, excerpt)
---------------------------------

Output: ``evmasm::LinkerObject`` with linked bytecode and metadata. The
increment sequence above corresponds to a bytecode excerpt like:

.. code-block:: text

   0x600054600101600055

Data Flow Highlights
====================

* The Solidity AST root node is ``SourceUnit`` (``libsolidity/ast/AST.h``).
* Semantic analysis decorates AST nodes via ``ASTAnnotations`` to attach types,
  scopes, and resolved declarations (``libsolidity/ast/ASTAnnotations.h``).
* The IR pipeline uses Yul as the intermediate representation; the data model is
  serialized Yul text, with the Yul AST defined in ``libyul/AST.h``.
* The final bytecode is represented as ``evmasm::LinkerObject`` and is
  accessible through ``CompilerStack::object`` / ``runtimeObject``.
