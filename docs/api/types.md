# Types and Constants

The FYAML library defines several important types and constants that form the foundation of the API.

## Core Types

### fyaml_t - Main Configuration Type

::: fyaml_types.fyaml_t
    handler: fortran
    options:
      show_source: true
      heading_level: 4

The primary container for parsed YAML data. This type holds all variables and metadata from a YAML file.

**Key Components:**
- `num_vars` - Number of loaded variables
- `vars(:)` - Array of variable containers
- `sorted` - Whether variables are sorted for fast lookup

### fyaml_var_t - Variable Container

::: fyaml_types.fyaml_var_t
    handler: fortran
    options:
      show_source: true
      heading_level: 4

Individual variable storage with type information and data.

**Key Components:**
- `var_name` - Variable identifier
- `var_type` - Data type indicator
- `var_size` - Array size (1 for scalars)
- Data arrays for each supported type

## Constants

### Return Codes

| Constant | Value | Description |
|----------|--------|-------------|
| `fyaml_Success` | 0 | Operation completed successfully |
| `fyaml_Failure` | -1 | Generic failure |

### Data Type Identifiers

| Constant | Value | Fortran Type | Description |
|----------|--------|--------------|-------------|
| `fyaml_unknown_type` | 0 | - | Type not yet determined |
| `fyaml_integer_type` | 1 | `integer` | Integer numbers |
| `fyaml_real_type` | 2 | `real(yp)` | Floating-point numbers |
| `fyaml_string_type` | 3 | `character(len=*)` | Text strings |
| `fyaml_bool_type` | 4 | `logical` | Boolean values |

### Size Limits

| Constant | Value | Purpose |
|----------|--------|---------|
| `fyaml_MaxArr` | 1000 | Maximum array size |
| `fyaml_MaxStack` | 50 | Maximum category nesting |
| `fyaml_NamLen` | 100 | Maximum variable name length |
| `fyaml_StrLen` | 512 | Maximum string content length |

### Special Characters

| Constant | Value | Purpose |
|----------|--------|---------|
| `fyaml_category_separator` | `%` | Separates category levels |
| `fyaml_separators` | `" ,'\"\\t"` | Array element separators |
| `fyaml_brackets` | `"{}[]"` | Array bracket characters |

## Precision Control

### yp - Working Precision

::: fyaml_precision.yp
    handler: fortran
    options:
      show_source: true
      heading_level: 4

The working precision parameter for all real numbers in FYAML.

**Default Configuration:**
```fortran
! Typically defined as:
integer, parameter :: yp = real64  ! Double precision
```

**Usage:**
```fortran
use fyaml_precision, only: yp
real(yp) :: my_real_value
call fyaml_get(config, "pi", my_real_value, RC)
```

## Type Usage Examples

### Basic Variable Access

```fortran
program type_example
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: int_val, RC
    real(yp) :: real_val
    character(len=fyaml_StrLen) :: string_val
    logical :: bool_val

    call fyaml_init("config.yml", config, RC=RC)

    ! Access different types
    call fyaml_get(config, "count", int_val, RC)
    call fyaml_get(config, "ratio", real_val, RC)
    call fyaml_get(config, "name", string_val, RC)
    call fyaml_get(config, "enabled", bool_val, RC)

    call fyaml_cleanup(config)
end program
```

### Array Variables

```fortran
program array_example
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, array_size
    integer, allocatable :: int_array(:)
    real(yp), allocatable :: real_array(:)

    call fyaml_init("arrays.yml", config, RC=RC)

    ! Get array size first
    call fyaml_get_size(config, "numbers", array_size, RC)
    allocate(int_array(array_size))

    ! Get array data
    call fyaml_get(config, "numbers", int_array, RC)

    call fyaml_cleanup(config)
end program
```

### Type Checking

```fortran
program type_check
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, var_type

    call fyaml_init("config.yml", config, RC=RC)

    ! Check variable type before accessing
    call fyaml_get_type(config, "my_var", var_type, RC)

    select case (var_type)
    case (fyaml_integer_type)
        ! Handle as integer
    case (fyaml_real_type)
        ! Handle as real
    case (fyaml_string_type)
        ! Handle as string
    case (fyaml_bool_type)
        ! Handle as boolean
    case default
        write(*,*) "Unknown type!"
    end select

    call fyaml_cleanup(config)
end program
```

## Memory Management

The `fyaml_t` type manages memory automatically:

- **Allocation**: Done during `fyaml_init()` or `fyaml_add()`
- **Reallocation**: Automatic when adding variables
- **Deallocation**: Must call `fyaml_cleanup()` explicitly

```fortran
! Always cleanup to prevent memory leaks
call fyaml_cleanup(config)
```

## Generated Type Documentation

For complete type definitions with all fields and detailed descriptions, see:

**[📖 Generated Types Documentation](../fyaml/namespacefyaml__types.md)**

This includes:
- Complete field lists for all types
- Memory layout details
- Inheritance relationships
- Cross-references to related procedures

## See Also

- **[Core Module API](fyaml.md)** - Main interface functions
- **[Basic Usage](../user-guide/basic-usage.md)** - Practical examples
- **[Data Types Guide](../user-guide/data-types.md)** - Working with different types
