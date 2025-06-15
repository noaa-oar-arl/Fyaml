# String Utilities

The FYAML string utilities module provides functions for string manipulation, formatting, and processing specifically designed for YAML data handling.

## Overview

The string utilities module (`fyaml_string_utils`) contains specialized functions for:

- String trimming and normalization
- Key path manipulation
- String escaping and unescaping
- Character encoding handling
- Pattern matching and validation

## ::: fyaml_string_utils

This section includes the complete API documentation for all string utility functions generated from the source code.

## Core String Functions

### String Trimming and Normalization

#### `fyaml_trim`

Removes leading and trailing whitespace from a string.

```fortran
function fyaml_trim(input_string) result(trimmed_string)
    character(len=*), intent(in) :: input_string
    character(len=:), allocatable :: trimmed_string
```

**Example:**
```fortran
character(len=:), allocatable :: clean_string
clean_string = fyaml_trim('  hello world  ')
! clean_string = 'hello world'
```

#### `fyaml_normalize_string`

Normalizes whitespace in strings (converts tabs to spaces, removes extra whitespace).

```fortran
function fyaml_normalize_string(input_string) result(normalized)
    character(len=*), intent(in) :: input_string
    character(len=:), allocatable :: normalized
```

#### `fyaml_strip_quotes`

Removes surrounding quotes from quoted strings.

```fortran
function fyaml_strip_quotes(quoted_string) result(unquoted)
    character(len=*), intent(in) :: quoted_string
    character(len=:), allocatable :: unquoted
```

**Example:**
```fortran
character(len=:), allocatable :: result
result = fyaml_strip_quotes('"hello world"')
! result = 'hello world'

result = fyaml_strip_quotes("'single quoted'")
! result = 'single quoted'
```

### Key Path Manipulation

#### `fyaml_split_path`

Splits a dot-separated key path into individual components.

```fortran
subroutine fyaml_split_path(key_path, components, num_components)
    character(len=*), intent(in) :: key_path
    character(len=:), allocatable, intent(out) :: components(:)
    integer, intent(out) :: num_components
```

**Example:**
```fortran
character(len=:), allocatable :: parts(:)
integer :: count

call fyaml_split_path('server.database.connection.host', parts, count)
! parts = ['server', 'database', 'connection', 'host']
! count = 4
```

#### `fyaml_join_path`

Joins path components into a dot-separated key path.

```fortran
function fyaml_join_path(components) result(key_path)
    character(len=*), intent(in) :: components(:)
    character(len=:), allocatable :: key_path
```

**Example:**
```fortran
character(len=20) :: parts(3) = ['server', 'port', 'number']
character(len=:), allocatable :: path
path = fyaml_join_path(parts)
! path = 'server.port.number'
```

#### `fyaml_parent_path`

Returns the parent path of a given key path.

```fortran
function fyaml_parent_path(key_path) result(parent)
    character(len=*), intent(in) :: key_path
    character(len=:), allocatable :: parent
```

**Example:**
```fortran
character(len=:), allocatable :: parent
parent = fyaml_parent_path('server.database.host')
! parent = 'server.database'
```

#### `fyaml_key_name`

Extracts the final key name from a key path.

```fortran
function fyaml_key_name(key_path) result(key)
    character(len=*), intent(in) :: key_path
    character(len=:), allocatable :: key
```

**Example:**
```fortran
character(len=:), allocatable :: key
key = fyaml_key_name('server.database.host')
! key = 'host'
```

### String Escaping and Unescaping

#### `fyaml_escape_string`

Escapes special characters in strings for YAML output.

```fortran
function fyaml_escape_string(input_string) result(escaped)
    character(len=*), intent(in) :: input_string
    character(len=:), allocatable :: escaped
```

**Example:**
```fortran
character(len=:), allocatable :: escaped
escaped = fyaml_escape_string('Line 1' // new_line('a') // 'Line 2')
! Properly escapes newlines for YAML
```

#### `fyaml_unescape_string`

Unescapes special characters from YAML strings.

```fortran
function fyaml_unescape_string(escaped_string) result(unescaped)
    character(len=*), intent(in) :: escaped_string
    character(len=:), allocatable :: unescaped
```

### Type Conversion Helpers

#### `fyaml_string_to_integer`

Converts a string to an integer with error checking.

```fortran
subroutine fyaml_string_to_integer(string_value, integer_value, status)
    character(len=*), intent(in) :: string_value
    integer, intent(out) :: integer_value
    integer, intent(out) :: status
```

**Example:**
```fortran
integer :: port, status
call fyaml_string_to_integer('8080', port, status)
if (status == FYAML_SUCCESS) then
    print *, 'Port:', port
end if
```

#### `fyaml_string_to_real`

Converts a string to a real number with error checking.

```fortran
subroutine fyaml_string_to_real(string_value, real_value, status)
    character(len=*), intent(in) :: string_value
    real, intent(out) :: real_value
    integer, intent(out) :: status
```

#### `fyaml_string_to_logical`

Converts a string to a logical value.

```fortran
subroutine fyaml_string_to_logical(string_value, logical_value, status)
    character(len=*), intent(in) :: string_value
    logical, intent(out) :: logical_value
    integer, intent(out) :: status
```

**Example:**
```fortran
logical :: debug_flag
integer :: status

call fyaml_string_to_logical('true', debug_flag, status)
call fyaml_string_to_logical('yes', debug_flag, status)
call fyaml_string_to_logical('on', debug_flag, status)
! All convert to .true.

call fyaml_string_to_logical('false', debug_flag, status)
call fyaml_string_to_logical('no', debug_flag, status)
call fyaml_string_to_logical('off', debug_flag, status)
! All convert to .false.
```

### String Validation

#### `fyaml_is_valid_identifier`

Checks if a string is a valid YAML identifier.

```fortran
logical function fyaml_is_valid_identifier(identifier)
    character(len=*), intent(in) :: identifier
```

#### `fyaml_is_quoted_string`

Checks if a string is quoted (single or double quotes).

```fortran
logical function fyaml_is_quoted_string(string_value)
    character(len=*), intent(in) :: string_value
```

#### `fyaml_needs_quoting`

Determines if a string needs to be quoted in YAML output.

```fortran
logical function fyaml_needs_quoting(string_value)
    character(len=*), intent(in) :: string_value
```

**Example:**
```fortran
logical :: needs_quotes

needs_quotes = fyaml_needs_quoting('hello world')  ! .false.
needs_quotes = fyaml_needs_quoting('hello: world') ! .true. (contains colon)
needs_quotes = fyaml_needs_quoting('123')          ! .true. (looks like number)
```

### Pattern Matching

#### `fyaml_match_pattern`

Simple pattern matching for string validation.

```fortran
logical function fyaml_match_pattern(string_value, pattern)
    character(len=*), intent(in) :: string_value
    character(len=*), intent(in) :: pattern
```

**Example:**
```fortran
logical :: matches

matches = fyaml_match_pattern('192.168.1.1', '*.*.*.* ')     ! IP pattern
matches = fyaml_match_pattern('user@host.com', '*@*.*')      ! Email pattern
```

### Character Utilities

#### `fyaml_char_count`

Counts occurrences of a character in a string.

```fortran
integer function fyaml_char_count(string_value, char_to_count)
    character(len=*), intent(in) :: string_value
    character, intent(in) :: char_to_count
```

#### `fyaml_find_char`

Finds the position of a character in a string.

```fortran
integer function fyaml_find_char(string_value, char_to_find, start_pos)
    character(len=*), intent(in) :: string_value
    character, intent(in) :: char_to_find
    integer, intent(in), optional :: start_pos
```

## Practical Examples

### Configuration Key Processing

```fortran
program process_keys
    use fyaml_string_utils
    implicit none

    character(len=*), parameter :: config_key = 'application.server.database.connection_string'
    character(len=:), allocatable :: components(:)
    character(len=:), allocatable :: parent, key_name
    integer :: num_parts, i

    ! Split the key path
    call fyaml_split_path(config_key, components, num_parts)

    print *, 'Key path components:'
    do i = 1, num_parts
        print *, '  ', i, ':', components(i)
    end do

    ! Get parent and key name
    parent = fyaml_parent_path(config_key)
    key_name = fyaml_key_name(config_key)

    print *, 'Parent path:', parent
    print *, 'Key name:', key_name
end program
```

### String Cleaning and Validation

```fortran
program clean_strings
    use fyaml_string_utils
    implicit none

    character(len=*), parameter :: messy_string = '  " hello world "  '
    character(len=:), allocatable :: cleaned

    ! Clean up the string
    cleaned = fyaml_trim(messy_string)
    cleaned = fyaml_strip_quotes(cleaned)

    print *, 'Original: [', messy_string, ']'
    print *, 'Cleaned:  [', cleaned, ']'

    ! Check if strings need quoting
    if (fyaml_needs_quoting('hello world')) then
        print *, 'hello world needs quoting'
    end if

    if (fyaml_needs_quoting('hello: world')) then
        print *, 'hello: world needs quoting (contains colon)'
    end if
end program
```

### Type Conversion with Error Handling

```fortran
program safe_conversion
    use fyaml_string_utils
    implicit none

    character(len=*), parameter :: port_str = '8080'
    character(len=*), parameter :: timeout_str = '30.5'
    character(len=*), parameter :: debug_str = 'true'

    integer :: port, status
    real :: timeout
    logical :: debug_mode

    ! Convert port
    call fyaml_string_to_integer(port_str, port, status)
    if (status == FYAML_SUCCESS) then
        print *, 'Port:', port
    else
        print *, 'Invalid port value'
    end if

    ! Convert timeout
    call fyaml_string_to_real(timeout_str, timeout, status)
    if (status == FYAML_SUCCESS) then
        print *, 'Timeout:', timeout
    else
        print *, 'Invalid timeout value'
    end if

    ! Convert debug flag
    call fyaml_string_to_logical(debug_str, debug_mode, status)
    if (status == FYAML_SUCCESS) then
        print *, 'Debug mode:', debug_mode
    else
        print *, 'Invalid debug value'
    end if
end program
```

### Dynamic Key Path Building

```fortran
program build_paths
    use fyaml_string_utils
    implicit none

    character(len=20) :: base_components(2) = ['server', 'database']
    character(len=20) :: config_keys(4) = ['host', 'port', 'username', 'password']
    character(len=:), allocatable :: full_path
    integer :: i

    do i = 1, size(config_keys)
        ! Build full path
        full_path = fyaml_join_path(base_components) // '.' // config_keys(i)
        print *, 'Configuration key:', full_path
    end do
end program
```

### String Pattern Validation

```fortran
program validate_formats
    use fyaml_string_utils
    implicit none

    character(len=*), parameter :: test_strings(5) = [ &
        '192.168.1.1     ', &
        'user@domain.com ', &
        'not-an-email    ', &
        '10.0.0.1        ', &
        'invalid@        ' &
    ]

    integer :: i

    print *, 'IP Address validation:'
    do i = 1, size(test_strings)
        if (fyaml_match_pattern(fyaml_trim(test_strings(i)), '*.*.*.* ')) then
            print *, '  Valid IP: ', fyaml_trim(test_strings(i))
        end if
    end do

    print *, 'Email validation:'
    do i = 1, size(test_strings)
        if (fyaml_match_pattern(fyaml_trim(test_strings(i)), '*@*.*')) then
            print *, '  Valid email: ', fyaml_trim(test_strings(i))
        end if
    end do
end program
```

## Performance Considerations

1. **Memory allocation** - String functions return allocatable strings; manage memory appropriately
2. **String length** - Be aware of maximum string lengths in your Fortran compiler
3. **Pattern matching** - Simple patterns only; not full regex support
4. **Character encoding** - Assumes ASCII/UTF-8 encoding

## Best Practices

1. **Always trim strings** - Remove whitespace before processing
2. **Validate before conversion** - Check string format before type conversion
3. **Handle allocation errors** - Check allocation status for large strings
4. **Use appropriate string lengths** - Size allocatable strings appropriately
5. **Escape special characters** - When building YAML output strings

## Common Patterns

### Safe String Processing Pipeline

```fortran
function process_yaml_string(input) result(output)
    character(len=*), intent(in) :: input
    character(len=:), allocatable :: output

    ! Standard string processing pipeline
    output = fyaml_trim(input)           ! Remove whitespace
    output = fyaml_strip_quotes(output)  ! Remove quotes if present
    output = fyaml_normalize_string(output) ! Normalize whitespace
end function
```

### Configuration Key Builder

```fortran
function build_config_key(section, subsection, key) result(full_key)
    character(len=*), intent(in) :: section, subsection, key
    character(len=:), allocatable :: full_key

    character(len=len(section)) :: parts(3)

    parts(1) = section
    parts(2) = subsection
    parts(3) = key

    full_key = fyaml_join_path(parts)
end function
```

## See Also

- [Utilities](utilities.md) - General utility functions
- [Core Module](fyaml.md) - Main FYAML functions
- [Data Types](../user-guide/data-types.md) - Understanding YAML types
- [Error Handling](error-handling.md) - String conversion error handling
