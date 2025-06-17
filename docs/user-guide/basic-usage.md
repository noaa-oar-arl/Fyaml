# Basic Usage

This guide covers the fundamental concepts and usage patterns for the FYAML library.

## Overview

FYAML provides a simple and intuitive interface for parsing YAML files in Fortran applications. The library is designed to be easy to use while providing powerful features for handling complex YAML structures.

## Basic Parsing

### Simple Key-Value Pairs

```fortran
program basic_example
    use fyaml
    implicit none

    type(fyaml_t) :: yaml_data
    character(len=:), allocatable :: value
    integer :: status

    ! Parse a simple YAML file
    call fyaml_parse_file('config.yml', yaml_data, status)
    if (status /= 0) then
        print *, 'Error parsing YAML file'
        stop 1
    end if

    ! Get a string value
    call fyaml_get(yaml_data, 'name', value, status)
    if (status == 0) then
        print *, 'Name: ', value
    end if

    ! Clean up
    call fyaml_destroy(yaml_data)
end program
```

### Working with Different Data Types

FYAML supports all common YAML data types:

```fortran
! Integer values
integer :: port
call fyaml_get(yaml_data, 'server.port', port, status)

! Real values
real :: timeout
call fyaml_get(yaml_data, 'server.timeout', timeout, status)

! Boolean values
logical :: debug_mode
call fyaml_get(yaml_data, 'debug', debug_mode, status)

! String values
character(len=:), allocatable :: hostname
call fyaml_get(yaml_data, 'server.hostname', hostname, status)
```

## Nested Structures

FYAML handles nested YAML structures using dot notation:

```yaml
# config.yml
server:
  hostname: localhost
  port: 8080
  ssl:
    enabled: true
    certificate: /path/to/cert.pem
```

```fortran
! Access nested values
call fyaml_get(yaml_data, 'server.hostname', hostname, status)
call fyaml_get(yaml_data, 'server.port', port, status)
call fyaml_get(yaml_data, 'server.ssl.enabled', ssl_enabled, status)
```

## Error Handling

Always check the status code returned by FYAML functions:

```fortran
integer :: status

call fyaml_get(yaml_data, 'some.key', value, status)

select case(status)
case(FYAML_SUCCESS)
    ! Success - use the value
    print *, 'Value: ', value
case(FYAML_KEY_NOT_FOUND)
    print *, 'Key not found in YAML data'
case(FYAML_TYPE_MISMATCH)
    print *, 'Type mismatch - wrong data type requested'
case default
    print *, 'Unknown error occurred'
end select
```

## File vs String Parsing

FYAML supports parsing from both files and strings:

```fortran
! Parse from file
call fyaml_parse_file('config.yml', yaml_data, status)

! Parse from string
character(len=*), parameter :: yaml_string = &
    'name: FYAML' // new_line('a') // &
    'version: 1.0' // new_line('a') // &
    'description: Fortran YAML Parser'

call fyaml_parse_string(yaml_string, yaml_data, status)
```

## Memory Management

Always destroy YAML data structures when done:

```fortran
! Create and use yaml_data
call fyaml_parse_file('config.yml', yaml_data, status)

! ... use yaml_data ...

! Clean up memory
call fyaml_destroy(yaml_data)
```

## Best Practices

1. **Always check status codes** - Never ignore the status returned by FYAML functions
2. **Use appropriate data types** - Match your Fortran variables to the YAML data types
3. **Handle missing keys gracefully** - Provide default values for optional configuration
4. **Clean up memory** - Always call `fyaml_destroy()` when done with YAML data
5. **Use meaningful variable names** - Make your code self-documenting

## Common Patterns

### Configuration Loading

```fortran
subroutine load_config(config_file, app_config)
    character(len=*), intent(in) :: config_file
    type(app_config_t), intent(out) :: app_config

    type(fyaml_t) :: yaml_data
    integer :: status

    call fyaml_parse_file(config_file, yaml_data, status)
    if (status /= 0) then
        call handle_parse_error(status)
        return
    end if

    ! Load configuration values with defaults
    call fyaml_get(yaml_data, 'app.name', app_config%name, status)
    if (status /= 0) app_config%name = 'DefaultApp'

    call fyaml_get(yaml_data, 'app.port', app_config%port, status)
    if (status /= 0) app_config%port = 8080

    call fyaml_destroy(yaml_data)
end subroutine
```

### Validation

```fortran
logical function validate_config(yaml_data)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=:), allocatable :: required_key
    integer :: status

    validate_config = .true.

    ! Check for required keys
    call fyaml_get(yaml_data, 'app.name', required_key, status)
    if (status /= 0) then
        print *, 'Error: app.name is required'
        validate_config = .false.
    end if

    ! Add more validation as needed
end function
```

## Next Steps

- Learn about [Data Types](data-types.md) for detailed type handling
- Explore [Arrays and Lists](arrays-lists.md) for sequence processing
- Study [Anchors and Aliases](anchors-aliases.md) for advanced YAML features
- Review [Error Handling](error-handling.md) for robust applications
