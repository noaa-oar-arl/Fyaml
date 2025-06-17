# Core Module (fyaml)

The `fyaml` module is the main public interface for the FYAML library. It provides high-level functions for parsing YAML files, managing configurations, and accessing data.

## Module Overview

The fyaml module serves as the primary entry point for all FYAML functionality. It re-exports essential types and constants from other modules while providing a clean, unified API.

!!! info "Auto-Generated Documentation"
    This page supplements the auto-generated API documentation. For complete details of all procedures, types, and parameters, see the [Generated API Documentation](../fyaml/).

## Key Features

- **High-level parsing interface** - Simple file-to-data conversion
- **Type-safe data access** - Strongly typed get/set operations
- **Configuration management** - Merge and manipulate YAML configs
- **Resource management** - Automatic memory management
- **Error handling** - Comprehensive error reporting

## Primary Interfaces

### Initialization

::: fyaml.fyaml_init
    handler: fortran
    options:
      show_source: true
      heading_level: 4

Initialize a FYAML configuration object from a file. This is the primary way to load YAML data.

**Example:**
```fortran
type(fyaml_t) :: config
integer :: RC

call fyaml_init("myconfig.yml", config, RC=RC)
if (RC /= fyaml_Success) then
    write(*,*) "Failed to load configuration"
    stop 1
endif
```

### Data Access

The module provides generic interfaces for type-safe data access:

#### fyaml_get - Retrieve Values

::: fyaml.fyaml_get
    handler: fortran
    options:
      show_source: true
      heading_level: 5

Generic interface for retrieving values of any supported type.

**Supported Types:**
- `integer` - Integer scalars and arrays
- `real(yp)` - Real scalars and arrays
- `character(len=*)` - String scalars and arrays
- `logical` - Boolean scalars and arrays

**Example:**
```fortran
integer :: workers, RC
real(yp) :: timeout
character(len=fyaml_StrLen) :: host
logical :: debug_mode

call fyaml_get(config, "workers", workers, RC)
call fyaml_get(config, "timeout", timeout, RC)
call fyaml_get(config, "database%host", host, RC)
call fyaml_get(config, "debug", debug_mode, RC)
```

#### fyaml_add - Store Values

::: fyaml.fyaml_add
    handler: fortran
    options:
      show_source: true
      heading_level: 5

Generic interface for adding values to a configuration.

**Example:**
```fortran
call fyaml_add(config, "new_setting", 42, "A new integer setting", RC)
call fyaml_add(config, "pi_value", 3.14159_yp, "Pi constant", RC)
```

### Utility Functions

#### fyaml_check - Variable Existence

::: fyaml.fyaml_check
    handler: fortran
    options:
      show_source: true
      heading_level: 5

Check if a variable exists in the configuration.

**Example:**
```fortran
logical :: exists
call fyaml_check(config, "optional_setting", exists)
if (exists) then
    call fyaml_get(config, "optional_setting", value, RC)
endif
```

#### fyaml_get_size - Array Dimensions

::: fyaml.fyaml_get_size
    handler: fortran
    options:
      show_source: true
      heading_level: 5

Get the size of an array variable.

**Example:**
```fortran
integer :: array_size, RC
integer, allocatable :: values(:)

call fyaml_get_size(config, "number_list", array_size, RC)
allocate(values(array_size))
call fyaml_get(config, "number_list", values, RC)
```

### Configuration Management

#### fyaml_merge - Combine Configurations

::: fyaml.fyaml_merge
    handler: fortran
    options:
      show_source: true
      heading_level: 5

Merge two YAML configurations, with the second overriding the first.

**Example:**
```fortran
type(fyaml_t) :: base_config, override_config, merged_config
integer :: RC

call fyaml_init("base.yml", base_config, RC=RC)
call fyaml_init("override.yml", override_config, RC=RC)
call fyaml_merge(base_config, override_config, merged_config, RC)
```

### Resource Management

#### fyaml_cleanup - Memory Cleanup

::: fyaml.fyaml_cleanup
    handler: fortran
    options:
      show_source: true
      heading_level: 5

Clean up memory and resources used by a YAML configuration.

**Example:**
```fortran
! Always cleanup when done
call fyaml_cleanup(config)
```

## Advanced Features

### Anchor Support

The fyaml module fully supports YAML anchors and merge keys through the underlying parser:

```yaml
# YAML file with anchors
defaults: &default_settings
  timeout: 30
  retries: 3

production:
  <<: *default_settings
  workers: 10
```

```fortran
! Access inherited values
call fyaml_get(config, "production%timeout", timeout, RC)  ! Gets 30
call fyaml_get(config, "production%workers", workers, RC)  ! Gets 10
```

### Category Navigation

Use dot notation to access nested configurations:

```fortran
call fyaml_get(config, "database%connection%host", db_host, RC)
call fyaml_get(config, "logging%level", log_level, RC)
```

### Error Handling Pattern

```fortran
subroutine safe_get_config()
    type(fyaml_t) :: config
    integer :: value, RC

    call fyaml_init("config.yml", config, RC=RC)
    if (RC /= fyaml_Success) return

    call fyaml_get(config, "important_value", value, RC)
    if (RC /= fyaml_Success) then
        write(*,*) "Warning: using default value"
        value = 42  ! Default
    endif

    call fyaml_cleanup(config)
end subroutine
```

## Complete API Reference

For the complete, auto-generated API documentation including all parameters, return values, and implementation details, visit:

**[📖 Generated fyaml Module Documentation](../fyaml/namespacefyaml.md)**

This includes:

- Complete parameter lists for all procedures
- Detailed descriptions from source code comments
- Cross-references to related functions
- Implementation details and source code links
- Full type definitions and constants

## Related Modules

- **[fyaml_types](types.md)** - Core data types and structures
- **[fyaml_utils](utilities.md)** - Lower-level parsing utilities
- **[fyaml_error](error-handling.md)** - Error handling system
- **[fyaml_string_utils](string-utils.md)** - String processing utilities

## See Also

- **[Basic Usage Guide](../user-guide/basic-usage.md)** - Step-by-step usage examples
- **[Anchors and Aliases](../user-guide/anchors-aliases.md)** - Advanced YAML features
- **[Error Handling](../user-guide/error-handling.md)** - Robust error management
