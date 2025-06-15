# Error Handling

FYAML provides comprehensive error handling facilities to help you identify and resolve issues when working with YAML documents.

## Error Types

FYAML defines several categories of errors:

- **Syntax Errors**: Invalid YAML syntax in the input document
- **Semantic Errors**: Valid YAML syntax but logically incorrect (e.g., duplicate keys)
- **I/O Errors**: Problems with file access or reading
- **Resolution Errors**: Issues with anchor/alias resolution or circular references
- **Type Errors**: Type mismatches when retrieving values

## Basic Error Handling

The simplest error handling pattern uses the status boolean returned by most FYAML functions:

```fortran
use fyaml

type(fyaml_config) :: config
logical :: status

status = fyaml_parse_file(config, "config.yml")
if (.not. status) then
    print *, "Failed to parse configuration file"
    ! Handle error or exit
    stop
end if
```

## Detailed Error Information

For more detailed error handling, FYAML provides an error object:

```fortran
use fyaml
use fyaml_error

type(fyaml_config) :: config
type(fyaml_error_type) :: error
logical :: status

status = fyaml_parse_file(config, "config.yml", error)
if (.not. status) then
    print *, "Error at line ", error%line, ", column ", error%column
    print *, "Error code: ", error%code
    print *, "Message: ", error%message
    stop
end if
```

## Error Codes

FYAML defines error code constants that can be used to identify specific error types:

```fortran
use fyaml_error

! Check for specific error types
if (error%code == FYAML_ERR_SYNTAX) then
    print *, "Syntax error in YAML document"
else if (error%code == FYAML_ERR_DUPLICATE_KEY) then
    print *, "Duplicate key found in document"
else if (error%code == FYAML_ERR_IO) then
    print *, "I/O error occurred"
end if
```

## Error Recovery

In some cases, you might want to recover from errors and continue processing:

```fortran
use fyaml
use fyaml_error

type(fyaml_config) :: config
type(fyaml_error_type) :: error
logical :: status
real :: value, default_value = 1.0

status = fyaml_get(config, "simulation.timestep", value, error)
if (.not. status) then
    if (error%code == FYAML_ERR_KEY_NOT_FOUND) then
        ! Key doesn't exist, use default value
        value = default_value
        print *, "Using default timestep:", default_value
    else
        ! Other error, report and exit
        print *, "Error:", error%message
        stop
    end if
end if
```

## Custom Error Handling

For applications with specific error handling requirements, you can define your own error handler:

```fortran
module my_error_handler
    use fyaml_error
    implicit none

    contains

    subroutine handle_fyaml_error(error)
        type(fyaml_error_type), intent(in) :: error

        ! Log the error
        call log_error("FYAML Error: " // error%message)

        ! Take action based on error code
        select case(error%code)
            case(FYAML_ERR_SYNTAX)
                call report_syntax_error(error)
            case(FYAML_ERR_IO)
                call attempt_io_recovery(error)
            case default
                call default_error_handler(error)
        end select
    end subroutine handle_fyaml_error

    ! Other handler subroutines...
end module my_error_handler
```

## Validation Errors

FYAML also provides facilities for validating YAML documents against a schema:

```fortran
use fyaml
use fyaml_validator

type(fyaml_config) :: config
type(fyaml_schema) :: schema
type(fyaml_error_type) :: error
logical :: status

! Load schema
status = fyaml_load_schema(schema, "schema.yml")

! Validate document against schema
status = fyaml_validate(config, schema, error)
if (.not. status) then
    print *, "Validation error: ", error%message
    stop
end if
```

## Error Context

For complex errors, FYAML can provide context about where in the document the error occurred:

```fortran
use fyaml
use fyaml_error

type(fyaml_config) :: config
type(fyaml_error_type) :: error
logical :: status

status = fyaml_parse_file(config, "config.yml", error)
if (.not. status) then
    print *, "Error: ", error%message
    print *, "Line ", error%line, ", Column ", error%column

    ! Get context from the document
    if (allocated(error%context)) then
        print *, "Context: ", error%context
    end if

    stop
end if
```

## Common Error Patterns

### Checking for Missing Keys

```fortran
status = fyaml_get(config, "simulation.timestep", value, error)
if (.not. status) then
    if (error%code == FYAML_ERR_KEY_NOT_FOUND) then
        print *, "Warning: timestep not specified, using default"
        value = default_value
    else
        print *, "Error:", error%message
        stop
    end if
end if
```

### Type Conversion Errors

```fortran
status = fyaml_get(config, "simulation.iterations", iterations, error)
if (.not. status) then
    if (error%code == FYAML_ERR_TYPE_CONVERSION) then
        print *, "Error: 'iterations' must be an integer"
    else
        print *, "Error:", error%message
    end if
    stop
end if
```

## API Reference

For more details on error handling functions and types, see:

- [Error Type Documentation](../fyaml/namespacefyaml__error.md)
- [Error Handling Constants](../api/types.md)
