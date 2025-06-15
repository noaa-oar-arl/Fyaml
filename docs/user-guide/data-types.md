# Data Types

FYAML supports all standard YAML data types and provides convenient interfaces for working with them in Fortran.

## Supported Types

### Scalars

FYAML supports the following scalar types:

| YAML Type | Fortran Type | Example |
|-----------|--------------|---------|
| String | `character(len=:), allocatable` | `name: "FYAML"` |
| Integer | `integer` | `port: 8080` |
| Real | `real` | `timeout: 30.5` |
| Boolean | `logical` | `debug: true` |

### Collections

| YAML Type | FYAML Support | Example |
|-----------|---------------|---------|
| Sequences (Arrays) | ✅ Supported | `[1, 2, 3]` |
| Mappings (Objects) | ✅ Supported | `{key: value}` |

## String Types

### Basic Strings

```yaml
# Plain strings (no quotes needed)
title: FYAML Library
author: Developer Name

# Quoted strings (when special characters are used)
description: "A YAML parser for Fortran: easy & powerful"
path: '/usr/local/bin'
```

```fortran
character(len=:), allocatable :: title, author, description, path

call fyaml_get(yaml_data, 'title', title, status)
call fyaml_get(yaml_data, 'author', author, status)
call fyaml_get(yaml_data, 'description', description, status)
call fyaml_get(yaml_data, 'path', path, status)
```

### Multi-line Strings

YAML supports several multi-line string formats:

```yaml
# Literal style (preserves newlines)
license_text: |
  Copyright (c) 2024 FYAML

  Permission is hereby granted, free of charge,
  to any person obtaining a copy of this software.

# Folded style (folds newlines to spaces)
description: >
  This is a long description that spans
  multiple lines but will be folded into
  a single line with spaces.
```

## Numeric Types

### Integers

```yaml
# Regular integers
port: 8080
max_connections: 1000

# Hexadecimal
flags: 0xFF

# Octal
permissions: 0o755

# Binary
mask: 0b1010
```

```fortran
integer :: port, max_connections, flags, permissions, mask

call fyaml_get(yaml_data, 'port', port, status)
call fyaml_get(yaml_data, 'max_connections', max_connections, status)
call fyaml_get(yaml_data, 'flags', flags, status)
call fyaml_get(yaml_data, 'permissions', permissions, status)
call fyaml_get(yaml_data, 'mask', mask, status)
```

### Real Numbers

```yaml
# Standard notation
timeout: 30.5
pi: 3.14159

# Scientific notation
avogadro: 6.02e23
planck: 6.626e-34

# Special values
infinity: .inf
not_a_number: .nan
```

```fortran
real :: timeout, pi
real(kind=real64) :: avogadro, planck
real :: infinity, not_a_number

call fyaml_get(yaml_data, 'timeout', timeout, status)
call fyaml_get(yaml_data, 'pi', pi, status)
call fyaml_get(yaml_data, 'avogadro', avogadro, status)
call fyaml_get(yaml_data, 'planck', planck, status)
call fyaml_get(yaml_data, 'infinity', infinity, status)
call fyaml_get(yaml_data, 'not_a_number', not_a_number, status)
```

## Boolean Types

YAML recognizes various boolean representations:

```yaml
# True values
debug: true
verbose: True
enabled: TRUE
on: on
yes: yes

# False values
production: false
quiet: False
disabled: FALSE
off: off
no: no
```

```fortran
logical :: debug, verbose, enabled, on_flag, yes_flag
logical :: production, quiet, disabled, off_flag, no_flag

call fyaml_get(yaml_data, 'debug', debug, status)
call fyaml_get(yaml_data, 'verbose', verbose, status)
call fyaml_get(yaml_data, 'enabled', enabled, status)
call fyaml_get(yaml_data, 'on', on_flag, status)
call fyaml_get(yaml_data, 'yes', yes_flag, status)

call fyaml_get(yaml_data, 'production', production, status)
call fyaml_get(yaml_data, 'quiet', quiet, status)
call fyaml_get(yaml_data, 'disabled', disabled, status)
call fyaml_get(yaml_data, 'off', off_flag, status)
call fyaml_get(yaml_data, 'no', no_flag, status)
```

## Null Values

```yaml
# Explicit null
database_password: null
optional_field: ~

# Implicit null (key with no value)
empty_value:
```

```fortran
! Check if a value is null/missing
call fyaml_get(yaml_data, 'database_password', password, status)
if (status == FYAML_NULL_VALUE) then
    print *, 'Password is null - using default'
    password = 'default_password'
end if
```

## Type Conversion and Validation

### Automatic Type Conversion

FYAML performs automatic type conversion when possible:

```fortran
! YAML: port: "8080"  (string)
! Fortran: integer
integer :: port
call fyaml_get(yaml_data, 'port', port, status)
if (status == 0) then
    ! Successful conversion from string "8080" to integer 8080
end if
```

### Type Validation

```fortran
subroutine validate_port(yaml_data, port, is_valid)
    type(fyaml_t), intent(in) :: yaml_data
    integer, intent(out) :: port
    logical, intent(out) :: is_valid

    integer :: status

    call fyaml_get(yaml_data, 'server.port', port, status)

    select case(status)
    case(FYAML_SUCCESS)
        if (port >= 1 .and. port <= 65535) then
            is_valid = .true.
        else
            is_valid = .false.
            print *, 'Port number out of valid range (1-65535)'
        end if
    case(FYAML_TYPE_MISMATCH)
        is_valid = .false.
        print *, 'Port must be an integer'
    case(FYAML_KEY_NOT_FOUND)
        is_valid = .false.
        print *, 'Port configuration missing'
    case default
        is_valid = .false.
        print *, 'Error reading port configuration'
    end select
end subroutine
```

## Working with Arrays

### Simple Arrays

```yaml
# Integer array
ports: [8080, 8081, 8082]

# String array
hosts: ["localhost", "127.0.0.1", "::1"]

# Mixed array (not recommended, but supported)
mixed: [42, "hello", true]
```

```fortran
! Get array size first
integer :: array_size, status
call fyaml_get_array_size(yaml_data, 'ports', array_size, status)

if (status == 0 .and. array_size > 0) then
    ! Allocate array
    integer, allocatable :: ports(:)
    allocate(ports(array_size))

    ! Get array values
    call fyaml_get_array(yaml_data, 'ports', ports, status)
end if
```

## Working with Objects

```yaml
server:
  hostname: localhost
  port: 8080
  ssl:
    enabled: true
    certificate: /path/to/cert.pem
    key: /path/to/key.pem
```

```fortran
! Access nested objects using dot notation
character(len=:), allocatable :: hostname, cert_path, key_path
integer :: port
logical :: ssl_enabled

call fyaml_get(yaml_data, 'server.hostname', hostname, status)
call fyaml_get(yaml_data, 'server.port', port, status)
call fyaml_get(yaml_data, 'server.ssl.enabled', ssl_enabled, status)
call fyaml_get(yaml_data, 'server.ssl.certificate', cert_path, status)
call fyaml_get(yaml_data, 'server.ssl.key', key_path, status)
```

## Complex Example

```yaml
# config.yml
application:
  name: "Scientific Computing App"
  version: 2.1
  debug: false

numerical:
  precision: double
  tolerance: 1.0e-12
  max_iterations: 1000

output:
  formats: ["hdf5", "vtk", "csv"]
  directory: "./results"
  compress: true

matrix:
  size: [100, 100, 50]
  initial_value: 0.0
```

```fortran
program complex_config_example
    use fyaml
    implicit none

    type(fyaml_t) :: yaml_data
    character(len=:), allocatable :: app_name, precision, output_dir
    real(kind=real64) :: version, tolerance, initial_value
    logical :: debug, compress
    integer :: max_iterations, array_size
    integer, allocatable :: matrix_size(:)
    character(len=20), allocatable :: formats(:)
    integer :: status, i

    ! Parse configuration
    call fyaml_parse_file('config.yml', yaml_data, status)
    if (status /= 0) stop 'Failed to parse config file'

    ! Read application settings
    call fyaml_get(yaml_data, 'application.name', app_name, status)
    call fyaml_get(yaml_data, 'application.version', version, status)
    call fyaml_get(yaml_data, 'application.debug', debug, status)

    ! Read numerical settings
    call fyaml_get(yaml_data, 'numerical.precision', precision, status)
    call fyaml_get(yaml_data, 'numerical.tolerance', tolerance, status)
    call fyaml_get(yaml_data, 'numerical.max_iterations', max_iterations, status)

    ! Read output settings
    call fyaml_get(yaml_data, 'output.directory', output_dir, status)
    call fyaml_get(yaml_data, 'output.compress', compress, status)

    ! Read output formats array
    call fyaml_get_array_size(yaml_data, 'output.formats', array_size, status)
    if (status == 0) then
        allocate(formats(array_size))
        call fyaml_get_array(yaml_data, 'output.formats', formats, status)
    end if

    ! Read matrix size array
    call fyaml_get_array_size(yaml_data, 'matrix.size', array_size, status)
    if (status == 0) then
        allocate(matrix_size(array_size))
        call fyaml_get_array(yaml_data, 'matrix.size', matrix_size, status)
    end if

    call fyaml_get(yaml_data, 'matrix.initial_value', initial_value, status)

    ! Use the configuration
    print *, 'Application:', app_name
    print *, 'Version:', version
    print *, 'Debug mode:', debug
    print *, 'Tolerance:', tolerance
    print *, 'Matrix dimensions:', matrix_size

    ! Clean up
    call fyaml_destroy(yaml_data)
end program
```

## Best Practices

1. **Use appropriate precision** - Choose `real` vs `real(kind=real64)` based on your needs
2. **Validate input data** - Always check types and ranges for critical values
3. **Handle type mismatches gracefully** - Provide meaningful error messages
4. **Use allocatable strings** - For variable-length string data
5. **Check array sizes** - Before allocating and reading array data

## See Also

- [Basic Usage](basic-usage.md) - Fundamental FYAML concepts
- [Arrays and Lists](arrays-lists.md) - Working with sequences
- [Error Handling](error-handling.md) - Robust error management
