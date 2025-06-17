# Error Handling

Robust error handling is crucial for reliable applications. FYAML provides comprehensive error reporting and recovery mechanisms.

## Error Codes

FYAML uses integer status codes to indicate the success or failure of operations:

```fortran
! Common FYAML error codes
integer, parameter :: FYAML_SUCCESS = 0
integer, parameter :: FYAML_KEY_NOT_FOUND = 1
integer, parameter :: FYAML_TYPE_MISMATCH = 2
integer, parameter :: FYAML_PARSE_ERROR = 3
integer, parameter :: FYAML_FILE_NOT_FOUND = 4
integer, parameter :: FYAML_MEMORY_ERROR = 5
integer, parameter :: FYAML_NULL_VALUE = 6
integer, parameter :: FYAML_INVALID_YAML = 7
integer, parameter :: FYAML_INDEX_OUT_OF_BOUNDS = 8
```

## Basic Error Checking

Always check the status code returned by FYAML functions:

```fortran
program basic_error_handling
    use fyaml
    implicit none

    type(fyaml_t) :: yaml_data
    character(len=:), allocatable :: value
    integer :: status

    ! Parse file with error checking
    call fyaml_parse_file('config.yml', yaml_data, status)
    if (status /= FYAML_SUCCESS) then
        print *, 'Error: Failed to parse YAML file'
        select case(status)
        case(FYAML_FILE_NOT_FOUND)
            print *, 'File not found: config.yml'
        case(FYAML_PARSE_ERROR)
            print *, 'Invalid YAML syntax'
        case(FYAML_MEMORY_ERROR)
            print *, 'Insufficient memory'
        case default
            print *, 'Unknown error code:', status
        end select
        stop 1
    end if

    ! Get value with error checking
    call fyaml_get(yaml_data, 'server.hostname', value, status)
    if (status /= FYAML_SUCCESS) then
        select case(status)
        case(FYAML_KEY_NOT_FOUND)
            print *, 'Using default hostname'
            value = 'localhost'
        case(FYAML_TYPE_MISMATCH)
            print *, 'Error: hostname must be a string'
            stop 1
        case default
            print *, 'Unexpected error reading hostname'
            stop 1
        end select
    end if

    print *, 'Hostname:', value
    call fyaml_destroy(yaml_data)
end program
```

## Error Handling Patterns

### Pattern 1: Early Return

```fortran
subroutine load_configuration(config_file, success)
    character(len=*), intent(in) :: config_file
    logical, intent(out) :: success

    type(fyaml_t) :: yaml_data
    integer :: status

    success = .false.

    ! Early return on parse failure
    call fyaml_parse_file(config_file, yaml_data, status)
    if (status /= FYAML_SUCCESS) then
        call log_error('Failed to parse configuration file', status)
        return
    end if

    ! Process configuration...
    ! Early return on any error

    success = .true.
    call fyaml_destroy(yaml_data)
end subroutine
```

### Pattern 2: Error Accumulation

```fortran
subroutine validate_config(yaml_data, is_valid, error_count)
    type(fyaml_t), intent(in) :: yaml_data
    logical, intent(out) :: is_valid
    integer, intent(out) :: error_count

    character(len=:), allocatable :: hostname
    integer :: port, status

    error_count = 0
    is_valid = .true.

    ! Validate hostname
    call fyaml_get(yaml_data, 'server.hostname', hostname, status)
    if (status == FYAML_KEY_NOT_FOUND) then
        print *, 'Error: server.hostname is required'
        error_count = error_count + 1
        is_valid = .false.
    else if (status == FYAML_TYPE_MISMATCH) then
        print *, 'Error: server.hostname must be a string'
        error_count = error_count + 1
        is_valid = .false.
    end if

    ! Validate port
    call fyaml_get(yaml_data, 'server.port', port, status)
    if (status == FYAML_KEY_NOT_FOUND) then
        print *, 'Error: server.port is required'
        error_count = error_count + 1
        is_valid = .false.
    else if (status == FYAML_TYPE_MISMATCH) then
        print *, 'Error: server.port must be an integer'
        error_count = error_count + 1
        is_valid = .false.
    else if (status == FYAML_SUCCESS) then
        if (port < 1 .or. port > 65535) then
            print *, 'Error: server.port must be between 1 and 65535'
            error_count = error_count + 1
            is_valid = .false.
        end if
    end if

    if (error_count > 0) then
        print *, 'Configuration validation failed with', error_count, 'errors'
    end if
end subroutine
```

### Pattern 3: Default Values

```fortran
subroutine get_config_with_defaults(yaml_data, config)
    type(fyaml_t), intent(in) :: yaml_data
    type(app_config_t), intent(out) :: config

    integer :: status

    ! Set defaults first
    config%hostname = 'localhost'
    config%port = 8080
    config%timeout = 30.0
    config%debug = .false.
    config%max_connections = 100

    ! Override with YAML values if present
    call fyaml_get(yaml_data, 'server.hostname', config%hostname, status)
    ! Ignore status - use default if not found

    call fyaml_get(yaml_data, 'server.port', config%port, status)
    if (status == FYAML_TYPE_MISMATCH) then
        print *, 'Warning: Invalid port value, using default'
    end if

    call fyaml_get(yaml_data, 'server.timeout', config%timeout, status)
    if (status == FYAML_TYPE_MISMATCH) then
        print *, 'Warning: Invalid timeout value, using default'
    end if

    call fyaml_get(yaml_data, 'debug', config%debug, status)
    ! Ignore status - use default if not found

    call fyaml_get(yaml_data, 'server.max_connections', config%max_connections, status)
    if (status == FYAML_TYPE_MISMATCH) then
        print *, 'Warning: Invalid max_connections value, using default'
    end if
end subroutine
```

## Advanced Error Handling

### Custom Error Messages

```fortran
subroutine get_required_string(yaml_data, key, value, success)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=*), intent(in) :: key
    character(len=:), allocatable, intent(out) :: value
    logical, intent(out) :: success

    integer :: status

    call fyaml_get(yaml_data, key, value, status)

    select case(status)
    case(FYAML_SUCCESS)
        success = .true.
    case(FYAML_KEY_NOT_FOUND)
        print *, 'Configuration error: Required key "' // key // '" not found'
        success = .false.
    case(FYAML_TYPE_MISMATCH)
        print *, 'Configuration error: Key "' // key // '" must be a string'
        success = .false.
    case(FYAML_NULL_VALUE)
        print *, 'Configuration error: Key "' // key // '" cannot be null'
        success = .false.
    case default
        print *, 'Unexpected error reading key "' // key // '": ', status
        success = .false.
    end select
end subroutine
```

### Error Context

```fortran
type :: error_context_t
    character(len=256) :: file_name
    character(len=256) :: current_key
    integer :: line_number
    character(len=512) :: error_message
end type

subroutine parse_with_context(config_file, yaml_data, context, success)
    character(len=*), intent(in) :: config_file
    type(fyaml_t), intent(out) :: yaml_data
    type(error_context_t), intent(out) :: context
    logical, intent(out) :: success

    integer :: status

    context%file_name = config_file
    context%current_key = ''
    context%line_number = 0
    context%error_message = ''

    call fyaml_parse_file(config_file, yaml_data, status)

    if (status /= FYAML_SUCCESS) then
        success = .false.
        select case(status)
        case(FYAML_FILE_NOT_FOUND)
            context%error_message = 'File not found: ' // trim(config_file)
        case(FYAML_PARSE_ERROR)
            context%error_message = 'YAML syntax error in file: ' // trim(config_file)
        case(FYAML_MEMORY_ERROR)
            context%error_message = 'Insufficient memory to parse: ' // trim(config_file)
        case default
            write(context%error_message, '(A,I0)') &
                'Unknown error parsing file: ' // trim(config_file) // ', code: ', status
        end select
    else
        success = .true.
    end if
end subroutine
```

### Logging Integration

```fortran
module fyaml_logging
    implicit none

    integer, parameter :: LOG_ERROR = 1
    integer, parameter :: LOG_WARNING = 2
    integer, parameter :: LOG_INFO = 3

contains

    subroutine log_fyaml_error(operation, key, status)
        character(len=*), intent(in) :: operation
        character(len=*), intent(in) :: key
        integer, intent(in) :: status

        character(len=512) :: message

        select case(status)
        case(FYAML_SUCCESS)
            return  ! No error to log
        case(FYAML_KEY_NOT_FOUND)
            write(message, '(A)') 'Key not found: ' // trim(key)
            call log_message(LOG_WARNING, operation, message)
        case(FYAML_TYPE_MISMATCH)
            write(message, '(A)') 'Type mismatch for key: ' // trim(key)
            call log_message(LOG_ERROR, operation, message)
        case(FYAML_PARSE_ERROR)
            write(message, '(A)') 'Parse error near key: ' // trim(key)
            call log_message(LOG_ERROR, operation, message)
        case default
            write(message, '(A,I0)') 'Unknown error (code ' // ', status) // &
                ') for key: ' // trim(key)
            call log_message(LOG_ERROR, operation, message)
        end select
    end subroutine

    subroutine log_message(level, operation, message)
        integer, intent(in) :: level
        character(len=*), intent(in) :: operation
        character(len=*), intent(in) :: message

        character(len=32) :: timestamp
        character(len=16) :: level_str

        call get_timestamp(timestamp)

        select case(level)
        case(LOG_ERROR)
            level_str = '[ERROR]'
        case(LOG_WARNING)
            level_str = '[WARNING]'
        case(LOG_INFO)
            level_str = '[INFO]'
        case default
            level_str = '[UNKNOWN]'
        end select

        print '(A,1X,A,1X,A,1X,A)', trim(timestamp), level_str, trim(operation), trim(message)
    end subroutine

end module
```

## Exception-Style Error Handling

For applications that prefer exception-style error handling:

```fortran
module fyaml_exceptions
    implicit none

    type :: fyaml_exception_t
        logical :: has_error = .false.
        integer :: error_code = 0
        character(len=256) :: error_message = ''
        character(len=256) :: error_context = ''
    end type

contains

    subroutine fyaml_get_safe(yaml_data, key, value, exception)
        type(fyaml_t), intent(in) :: yaml_data
        character(len=*), intent(in) :: key
        character(len=:), allocatable, intent(out) :: value
        type(fyaml_exception_t), intent(out) :: exception

        integer :: status

        call fyaml_get(yaml_data, key, value, status)

        if (status /= FYAML_SUCCESS) then
            exception%has_error = .true.
            exception%error_code = status
            exception%error_context = key

            select case(status)
            case(FYAML_KEY_NOT_FOUND)
                exception%error_message = 'Key not found'
            case(FYAML_TYPE_MISMATCH)
                exception%error_message = 'Type mismatch'
            case default
                write(exception%error_message, '(A,I0)') 'Error code: ', status
            end select
        end if
    end subroutine

    subroutine check_exception(exception, operation)
        type(fyaml_exception_t), intent(in) :: exception
        character(len=*), intent(in) :: operation

        if (exception%has_error) then
            print *, 'Exception in ', operation, ':'
            print *, '  Error:', trim(exception%error_message)
            print *, '  Context:', trim(exception%error_context)
            print *, '  Code:', exception%error_code
            stop 1
        end if
    end subroutine

end module
```

Usage:

```fortran
program exception_example
    use fyaml
    use fyaml_exceptions
    implicit none

    type(fyaml_t) :: yaml_data
    type(fyaml_exception_t) :: exception
    character(len=:), allocatable :: hostname
    integer :: status

    call fyaml_parse_file('config.yml', yaml_data, status)
    if (status /= FYAML_SUCCESS) stop 'Parse error'

    call fyaml_get_safe(yaml_data, 'server.hostname', hostname, exception)
    call check_exception(exception, 'reading hostname')

    print *, 'Hostname:', hostname
    call fyaml_destroy(yaml_data)
end program
```

## Best Practices

1. **Always check status codes** - Never ignore return values from FYAML functions
2. **Provide meaningful error messages** - Help users understand what went wrong
3. **Use appropriate error handling patterns** - Choose based on your application's needs
4. **Log errors appropriately** - Consider your application's logging framework
5. **Handle missing keys gracefully** - Provide sensible defaults when possible
6. **Validate critical configuration** - Fail fast on invalid critical settings
7. **Clean up on errors** - Always call `fyaml_destroy()` even after errors

## Common Error Scenarios

### File Not Found

```fortran
call fyaml_parse_file('missing.yml', yaml_data, status)
if (status == FYAML_FILE_NOT_FOUND) then
    print *, 'Config file not found, creating default configuration'
    call create_default_config('missing.yml')
    call fyaml_parse_file('missing.yml', yaml_data, status)
end if
```

### Invalid YAML Syntax

```fortran
call fyaml_parse_file('invalid.yml', yaml_data, status)
if (status == FYAML_PARSE_ERROR) then
    print *, 'Invalid YAML syntax detected.'
    print *, 'Please check your YAML file for:'
    print *, '  - Proper indentation (spaces, not tabs)'
    print *, '  - Matching quotes'
    print *, '  - Valid YAML structure'
    stop 1
end if
```

### Type Safety

```fortran
! Safe integer parsing with range validation
subroutine get_port_safe(yaml_data, port, success)
    type(fyaml_t), intent(in) :: yaml_data
    integer, intent(out) :: port
    logical, intent(out) :: success

    integer :: status

    call fyaml_get(yaml_data, 'server.port', port, status)

    success = .false.

    select case(status)
    case(FYAML_SUCCESS)
        if (port >= 1 .and. port <= 65535) then
            success = .true.
        else
            print *, 'Error: Port must be between 1 and 65535, got:', port
        end if
    case(FYAML_KEY_NOT_FOUND)
        print *, 'Error: server.port is required'
    case(FYAML_TYPE_MISMATCH)
        print *, 'Error: server.port must be an integer'
    case default
        print *, 'Unexpected error reading server.port:', status
    end select
end subroutine
```

## See Also

- [Basic Usage](basic-usage.md) - Fundamental FYAML operations
- [Data Types](data-types.md) - Understanding YAML type system
- [Configuration Files](configuration-files.md) - Best practices for config files
