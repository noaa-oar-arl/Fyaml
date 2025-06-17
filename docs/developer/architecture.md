# Architecture

This document describes the architecture of the FYAML library, providing an overview of its components and how they interact.

## High-Level Overview

FYAML is structured using a modular architecture that separates different concerns:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Parser    │────▶│ YAML Object │────▶│   Output    │
│   Module    │     │     Tree    │     │  Formatter  │
└─────────────┘     └─────────────┘     └─────────────┘
       ▲                  ▲                   ▲
       │                  │                   │
       └──────────────────┼───────────────────┘
                          │
                    ┌─────────────┐
                    │   Error     │
                    │   Handler   │
                    └─────────────┘
```

The key components are:

1. **Parser Module**: Handles reading and parsing YAML from files or strings
2. **YAML Object Tree**: Internal representation of YAML data
3. **Output Formatter**: Converts the object tree back to YAML text
4. **Error Handler**: Provides detailed error information

## Core Modules

### FYAML Core (`fyaml.f90`)

The core module provides the main interfaces for users and coordinates the other modules.

```fortran
module fyaml
    use fyaml_types
    use fyaml_parser
    use fyaml_error
    use fyaml_utils
    ! ...
end module fyaml
```

### Types Module (`fyaml_types.f90`)

Defines the fundamental data types and structures used throughout the library:

```fortran
module fyaml_types
    ! Node type definitions
    type :: fyaml_node_type
        ! ...
    end type

    ! Config container
    type :: fyaml_config
        ! ...
    end type

    ! ...
end module fyaml_types
```

### Parser Module (`fyaml_parser.f90`)

Handles the parsing of YAML documents:

```fortran
module fyaml_parser
    use fyaml_types
    use fyaml_error
    ! ...

    ! Parser implementation
    ! ...
end module fyaml_parser
```

### Error Module (`fyaml_error.f90`)

Provides error reporting and handling capabilities:

```fortran
module fyaml_error
    ! Error type definition
    type :: fyaml_error_type
        integer :: code
        integer :: line
        integer :: column
        character(len=:), allocatable :: message
        character(len=:), allocatable :: context
    end type

    ! Error constants
    integer, parameter :: FYAML_ERR_NONE = 0
    integer, parameter :: FYAML_ERR_SYNTAX = 1
    ! ...
end module fyaml_error
```

### Utilities Module (`fyaml_utils.f90`)

Contains helper functions and utilities:

```fortran
module fyaml_utils
    ! General utility functions
    ! ...
end module fyaml_utils
```

### String Utilities (`fyaml_string_utils.f90`)

Specialized utilities for string handling:

```fortran
module fyaml_string_utils
    ! String manipulation functions
    ! ...
end module fyaml_string_utils
```

## Data Flow

1. **Input Processing**
   - User calls `fyaml_parse_file()` or `fyaml_parse_string()`
   - Parser reads the input and tokenizes it
   - Parser constructs a syntactic tree

2. **Object Construction**
   - Parser builds the YAML object tree
   - Anchors and aliases are recorded for later resolution

3. **Resolution Phase**
   - References (anchors/aliases) are resolved
   - Merge keys are processed
   - Final object tree is constructed

4. **Data Access**
   - User calls `fyaml_get()` with a path expression
   - Library traverses the object tree to find the specified node
   - Value is converted to the requested Fortran type

5. **Output Generation**
   - User calls `fyaml_write_file()` or similar
   - Object tree is serialized back to YAML format

## Internal Data Structures

### YAML Node Types

FYAML represents YAML content using a hierarchy of node types:

- **Scalar**: Simple values (strings, numbers, booleans)
- **Sequence**: Ordered list of nodes
- **Mapping**: Key-value pairs of nodes
- **Document**: Container for the root node

### Path Expressions

FYAML uses dot notation and array indices for path expressions:

- `config.server.port`: Accesses a nested mapping
- `users[0].name`: Accesses an array element's property
- `matrix[1][2]`: Accesses a nested array element

## Memory Management

FYAML takes care of memory management internally:

1. When parsing a document, memory is allocated for the object tree
2. When accessing data, temporary allocations may occur for string conversions
3. When a configuration object is finalized, all allocated memory is released

## Thread Safety

FYAML is designed with thread safety in mind:

- Configuration objects are self-contained and can be used independently in different threads
- The parser does not use global variables that would affect thread safety
- Error handling is thread-local

## Extension Points

FYAML provides several extension points:

1. **Custom Tags**: Users can register handlers for custom YAML tags
2. **Validation Hooks**: Custom validation can be injected during parsing
3. **Error Handlers**: Custom error handling can be implemented
4. **Output Formatters**: Custom output formatting can be defined

## Performance Considerations

FYAML is designed to balance performance and features:

- Efficient memory usage with minimal copying
- Optimized string handling for Fortran
- Lazy resolution of anchors and aliases
- Caching of frequently accessed paths

## Testing Strategy

FYAML uses a comprehensive testing approach:

- Unit tests for individual components
- Integration tests for combined functionality
- Conformance tests against the YAML specification
- Performance benchmarks for critical operations

See the [Testing](testing.md) document for details on the testing infrastructure.
