# Utilities

The FYAML utilities module provides helper functions and convenience routines for common YAML operations.

## Overview

The utilities module (`fyaml_utils`) contains functions that simplify common tasks when working with YAML data, such as:

- Data validation and type checking
- String manipulation and formatting
- Array and object traversal
- Configuration merging and transformation

## ::: fyaml_utils

This section includes the complete API documentation for all utility functions generated from the source code.

## Common Utility Functions

### Data Validation

#### `fyaml_is_valid_key`

Checks if a given key path is valid in the YAML structure.

```fortran
logical function fyaml_is_valid_key(yaml_data, key_path)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=*), intent(in) :: key_path
```

**Parameters:**
- `yaml_data`: The YAML data structure to search
- `key_path`: Dot-separated key path (e.g., "server.database.host")

**Returns:**
- `.true.` if the key exists, `.false.` otherwise

**Example:**
```fortran
if (fyaml_is_valid_key(yaml_data, 'server.port')) then
    call fyaml_get(yaml_data, 'server.port', port, status)
end if
```

#### `fyaml_get_type`

Returns the data type of a value at the specified key path.

```fortran
integer function fyaml_get_type(yaml_data, key_path)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=*), intent(in) :: key_path
```

**Returns:**
- `FYAML_TYPE_STRING`, `FYAML_TYPE_INTEGER`, `FYAML_TYPE_REAL`, `FYAML_TYPE_BOOLEAN`, `FYAML_TYPE_ARRAY`, `FYAML_TYPE_OBJECT`, or `FYAML_TYPE_NULL`

### Array Operations

#### `fyaml_get_array_size`

Gets the size of an array in the YAML data.

```fortran
subroutine fyaml_get_array_size(yaml_data, key_path, size, status)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=*), intent(in) :: key_path
    integer, intent(out) :: size
    integer, intent(out) :: status
```

**Example:**
```fortran
integer :: array_size, status
call fyaml_get_array_size(yaml_data, 'hosts', array_size, status)
if (status == FYAML_SUCCESS) then
    allocate(host_list(array_size))
end if
```

#### `fyaml_array_contains`

Checks if an array contains a specific value.

```fortran
logical function fyaml_array_contains(yaml_data, key_path, value)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=*), intent(in) :: key_path
    class(*), intent(in) :: value
```

### Object Operations

#### `fyaml_get_keys`

Retrieves all keys from an object at the specified path.

```fortran
subroutine fyaml_get_keys(yaml_data, key_path, keys, num_keys, status)
    type(fyaml_t), intent(in) :: yaml_data
    character(len=*), intent(in) :: key_path
    character(len=:), allocatable, intent(out) :: keys(:)
    integer, intent(out) :: num_keys
    integer, intent(out) :: status
```

**Example:**
```fortran
character(len=:), allocatable :: server_keys(:)
integer :: num_keys, status

call fyaml_get_keys(yaml_data, 'server', server_keys, num_keys, status)
if (status == FYAML_SUCCESS) then
    do i = 1, num_keys
        print *, 'Server setting:', server_keys(i)
    end do
end if
```

### String Utilities

#### `fyaml_trim_string`

Removes leading and trailing whitespace from strings.

```fortran
function fyaml_trim_string(input_string) result(trimmed)
    character(len=*), intent(in) :: input_string
    character(len=:), allocatable :: trimmed
```

#### `fyaml_split_key_path`

Splits a dot-separated key path into individual components.

```fortran
subroutine fyaml_split_key_path(key_path, components, num_components)
    character(len=*), intent(in) :: key_path
    character(len=:), allocatable, intent(out) :: components(:)
    integer, intent(out) :: num_components
```

**Example:**
```fortran
character(len=:), allocatable :: parts(:)
integer :: num_parts

call fyaml_split_key_path('server.database.host', parts, num_parts)
! parts = ['server', 'database', 'host']
! num_parts = 3
```

### Configuration Merging

#### `fyaml_merge_configs`

Merges two YAML configurations, with the second taking precedence.

```fortran
subroutine fyaml_merge_configs(base_config, override_config, merged_config, status)
    type(fyaml_t), intent(in) :: base_config
    type(fyaml_t), intent(in) :: override_config
    type(fyaml_t), intent(out) :: merged_config
    integer, intent(out) :: status
```

**Example:**
```fortran
type(fyaml_t) :: default_config, user_config, final_config
integer :: status

call fyaml_parse_file('defaults.yml', default_config, status)
call fyaml_parse_file('user_config.yml', user_config, status)

call fyaml_merge_configs(default_config, user_config, final_config, status)
```

### Environment Variable Expansion

#### `fyaml_expand_variables`

Expands environment variables in YAML string values.

```fortran
subroutine fyaml_expand_variables(yaml_data, status)
    type(fyaml_t), intent(inout) :: yaml_data
    integer, intent(out) :: status
```

**Example:**
```yaml
# config.yml with environment variables
database:
  host: ${DB_HOST:-localhost}
  port: ${DB_PORT:-5432}
  name: ${DB_NAME}
```

```fortran
call fyaml_parse_file('config.yml', yaml_data, status)
call fyaml_expand_variables(yaml_data, status)
! Environment variables are now expanded
```

### Validation Utilities

#### `fyaml_validate_schema`

Validates YAML data against a simple schema.

```fortran
subroutine fyaml_validate_schema(yaml_data, schema, is_valid, errors, status)
    type(fyaml_t), intent(in) :: yaml_data
    type(fyaml_schema_t), intent(in) :: schema
    logical, intent(out) :: is_valid
    type(fyaml_error_list_t), intent(out) :: errors
    integer, intent(out) :: status
```

### Debug and Inspection

#### `fyaml_print_structure`

Prints the structure of YAML data for debugging.

```fortran
subroutine fyaml_print_structure(yaml_data, max_depth)
    type(fyaml_t), intent(in) :: yaml_data
    integer, intent(in), optional :: max_depth
```

**Example:**
```fortran
! Print the entire structure
call fyaml_print_structure(yaml_data)

! Print only top 2 levels
call fyaml_print_structure(yaml_data, max_depth=2)
```

#### `fyaml_get_statistics`

Returns statistics about the YAML data structure.

```fortran
subroutine fyaml_get_statistics(yaml_data, stats)
    type(fyaml_t), intent(in) :: yaml_data
    type(fyaml_stats_t), intent(out) :: stats
```

```fortran
type :: fyaml_stats_t
    integer :: num_keys
    integer :: num_arrays
    integer :: num_objects
    integer :: max_depth
    integer :: total_string_length
end type
```

## Practical Examples

### Configuration Validation

```fortran
program validate_config
    use fyaml
    use fyaml_utils
    implicit none

    type(fyaml_t) :: config
    character(len=:), allocatable :: required_keys(:)
    integer :: status, i
    logical :: all_present

    ! Define required configuration keys
    required_keys = ['server.host', 'server.port', 'database.name']

    call fyaml_parse_file('config.yml', config, status)
    if (status /= FYAML_SUCCESS) stop 'Failed to parse config'

    ! Validate all required keys are present
    all_present = .true.
    do i = 1, size(required_keys)
        if (.not. fyaml_is_valid_key(config, required_keys(i))) then
            print *, 'Missing required key:', required_keys(i)
            all_present = .false.
        end if
    end do

    if (.not. all_present) then
        print *, 'Configuration validation failed'
        stop 1
    end if

    print *, 'Configuration is valid'
    call fyaml_destroy(config)
end program
```

### Dynamic Configuration Processing

```fortran
program dynamic_config
    use fyaml
    use fyaml_utils
    implicit none

    type(fyaml_t) :: config
    character(len=:), allocatable :: server_keys(:)
    integer :: num_keys, status, i, port
    character(len=:), allocatable :: key_name, full_key

    call fyaml_parse_file('config.yml', config, status)

    ! Get all server configuration keys
    call fyaml_get_keys(config, 'server', server_keys, num_keys, status)

    print *, 'Found', num_keys, 'server configuration keys:'
    do i = 1, num_keys
        key_name = server_keys(i)
        full_key = 'server.' // key_name

        select case(fyaml_get_type(config, full_key))
        case(FYAML_TYPE_STRING)
            print *, '  ', key_name, ': [string]'
        case(FYAML_TYPE_INTEGER)
            print *, '  ', key_name, ': [integer]'
        case(FYAML_TYPE_BOOLEAN)
            print *, '  ', key_name, ': [boolean]'
        case default
            print *, '  ', key_name, ': [other]'
        end select
    end do

    call fyaml_destroy(config)
end program
```

### Configuration Merging Example

```fortran
program merge_configs
    use fyaml
    use fyaml_utils
    implicit none

    type(fyaml_t) :: defaults, user_config, production_config, final_config
    integer :: status

    ! Load configuration hierarchy
    call fyaml_parse_file('defaults.yml', defaults, status)
    call fyaml_parse_file('user_config.yml', user_config, status)
    call fyaml_parse_file('production.yml', production_config, status)

    ! Merge in order of precedence
    call fyaml_merge_configs(defaults, user_config, final_config, status)
    call fyaml_merge_configs(final_config, production_config, final_config, status)

    ! Expand environment variables
    call fyaml_expand_variables(final_config, status)

    ! The final_config now contains the merged configuration
    print *, 'Configuration merged successfully'

    ! Print debug information
    call fyaml_print_structure(final_config, max_depth=3)

    ! Clean up
    call fyaml_destroy(defaults)
    call fyaml_destroy(user_config)
    call fyaml_destroy(production_config)
    call fyaml_destroy(final_config)
end program
```

## Best Practices

1. **Use validation utilities** - Always validate configuration before using it
2. **Check key existence** - Use `fyaml_is_valid_key` before attempting to read values
3. **Handle arrays safely** - Get array size before allocation
4. **Merge configurations carefully** - Understand precedence rules when merging
5. **Debug with structure printing** - Use `fyaml_print_structure` for troubleshooting

## See Also

- [Basic Usage](../user-guide/basic-usage.md) - Fundamental FYAML operations
- [Error Handling](error-handling.md) - Comprehensive error handling
- [String Utils](string-utils.md) - String manipulation utilities
- [Core Module](fyaml.md) - Main FYAML functions
