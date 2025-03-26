---
title: Fyaml
author: Barry Baker
version: 0.1.0
summary: Modern YAML Parser for Fortran
---

# Fyaml: Modern YAML Parser for Fortran

## Overview

Fyaml provides a robust, easy-to-use YAML parser for Fortran applications. It handles complex YAML structures while maintaining type safety and memory efficiency.

## Getting Started

### Installation

```bash
git clone https://github.com/yourusername/fyaml.git
cd fyaml
mkdir build && cd build
cmake ..
make install
```

## Basic Usage

Read a Yaml Configuration file:

```yaml
# config.yaml
server:
  host: localhost
  ports:
    - 8080
    - 8081
  settings:
    timeout: 30
    debug: true
```

Parse it in your Fortran code:

```fortran
program example
    use fyaml
    type(fyaml_doc) :: doc
    type(yaml_value) :: val
    integer, allocatable :: ports(:)

    ! Load configuration
    call doc%load("config.yaml")

    ! Access string values
    val = doc%root%get("server.host")
    print *, "Host:", val%str_val

    ! Access arrays
    val = doc%root%get("server.ports")
    ports = val%int_array
    print *, "Ports:", ports

    ! Access nested values
    val = doc%root%get("server.settings.timeout")
    print *, "Timeout:", val%int_val
end program
```

## Core Features
- Type Safety: Native Fortran type handling
- Memory Management: Automatic cleanup of resources
- Flexible Access: Dot notation for nested structures
- Rich Data Types: Support for:
  - Strings
  - Integers
  - Real numbers
  - Booleans
  - Arrays
  - Nested structures
  - Null values

## API Documentation

### Core Modules

- [[yaml_types(module)]] - Core type definitions and data structures
- [[yaml_parser(module)]] - YAML parsing implementation
- [[fyaml(module)]] - High-level interface

### Key Types

```fortran
! Document container
type :: fyaml_doc
    type(yaml_dict) :: root
contains
    procedure :: load
end type

! Value container
type :: yaml_value
    integer :: value_type
    character(len=:), allocatable :: str_val
    integer :: int_val
    real :: real_val
    logical :: bool_val
    type(yaml_dict), pointer :: dict_val => null()
end type
```

## Advanced Usage

### Error Handling

```fortran
program error_handling
    use fyaml
    type(fyaml_doc) :: doc
    integer :: status

    call doc%load("config.yaml", status)
    if (status /= 0) then
        print *, "Failed to load configuration"
        stop 1
    endif
end program
```

### Working with Arrays
```fortran
! Read sequence of values
val = doc%get("database.ports")
if (val%is_sequence()) then
    ports = val%int_array
endif
```

### Get all keys from a node
```fortran
program example
    use fyaml
    type(fyaml_doc) :: doc
    type(yaml_value) :: root_value
    character(len=:), allocatable, dimension(:) :: keys
    logical :: success

    call doc%load("example.yaml", success)
    if (.not. success) then
        write(error_unit,*) 'Error: Failed to load YAML file'
        error stop
    end if

    root_value = doc%root
    keys = root_value%dict_val%keys()
    print *, "Root keys:", keys
end program
```

### Debug Output with Configurable Levels

```fortran
use yaml_parser, only: set_debug_level, DEBUG_SILENT, DEBUG_ERROR, DEBUG_INFO
call set_debug_level(DEBUG_INFO)   ! verbose
call set_debug_level(DEBUG_ERROR)  ! only errors
call set_debug_level(DEBUG_SILENT) ! quiet
```

### Examples
See our examples directory for:

- Basic configuration reading
- Complex data structures
- Error handling
- Type conversion
- Array handling

### Contributing
We welcome contributions! See our contribution guidelines.

### License
Licensed under GNU General Public License v3.0
