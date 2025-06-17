# Quick Start Guide

Get up and running with FYAML in minutes! This guide walks you through installation, basic usage, and your first YAML parsing program.

## Prerequisites

- **Fortran Compiler**: gfortran 10+ or Intel Fortran
- **CMake**: Version 3.12 or higher
- **Git**: For cloning the repository

## Installation

### Option 1: Build from Source (Recommended)

```bash
# Clone the repository
git clone https://github.com/your-username/fyaml.git
cd fyaml

# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build the library
make

# Run tests to verify installation
make test
```

### Option 2: FPM Integration

Add FYAML to your `fpm.toml`:

```toml
[dependencies]
fyaml = { git = "https://github.com/your-username/fyaml.git" }
```

### Option 3: Manual Integration

1. Copy the `src/` directory to your project
2. Compile all `.f90` files in dependency order
3. Link against the resulting object files

## Your First FYAML Program

### Step 1: Create a YAML File

Create `config.yml`:

```yaml
# Simple configuration
app_name: "My Application"
version: 1.0
debug: true
max_connections: 100

# Nested configuration
database:
  host: "localhost"
  port: 5432
  name: "myapp_db"

# Arrays
allowed_ips: ["127.0.0.1", "192.168.1.0/24"]
retry_delays: [1.0, 2.0, 5.0, 10.0]
```

### Step 2: Write Your Program

Create `example.f90`:

```fortran
program quick_start
    use fyaml
    implicit none

    ! Variables
    type(fyaml_t) :: config
    integer :: RC

    ! Data variables
    character(len=fyaml_StrLen) :: app_name, db_host
    real(yp) :: version
    logical :: debug
    integer :: max_connections, db_port

    ! Initialize configuration from file
    call fyaml_init("config.yml", config, RC=RC)
    if (RC /= fyaml_Success) then
        write(*,*) "Error: Could not load config.yml"
        stop 1
    endif

    ! Read simple values
    call fyaml_get(config, "app_name", app_name, RC)
    call fyaml_get(config, "version", version, RC)
    call fyaml_get(config, "debug", debug, RC)
    call fyaml_get(config, "max_connections", max_connections, RC)

    ! Read nested values using category notation
    call fyaml_get(config, "database%host", db_host, RC)
    call fyaml_get(config, "database%port", db_port, RC)

    ! Display results
    write(*,*) "Application:", trim(app_name)
    write(*,*) "Version:", version
    write(*,*) "Debug mode:", debug
    write(*,*) "Max connections:", max_connections
    write(*,*) "Database:", trim(db_host), ":", db_port

    ! Always cleanup
    call fyaml_cleanup(config)
end program quick_start
```

### Step 3: Compile and Run

```bash
# Using gfortran with the built library
gfortran -I../build/include -L../build/src -o example example.f90 -lfyaml

# Run the program
./example
```

**Expected Output:**
```
Application: My Application
Version:    1.0000000000000000
Debug mode:  T
Max connections:         100
Database: localhost :        5432
```

## Working with Arrays

Arrays in YAML are automatically handled by FYAML:

### YAML File (`arrays.yml`):
```yaml
numbers: [1, 2, 3, 4, 5]
coordinates: [10.5, 20.3, 30.7]
names: ["Alice", "Bob", "Charlie"]
flags: [true, false, true]
```

### Fortran Code:
```fortran
program array_example
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, i, array_size

    ! Array variables
    integer, allocatable :: numbers(:)
    real(yp), allocatable :: coordinates(:)
    character(len=fyaml_StrLen), allocatable :: names(:)
    logical, allocatable :: flags(:)

    call fyaml_init("arrays.yml", config, RC=RC)

    ! Get array sizes and allocate
    call fyaml_get_size(config, "numbers", array_size, RC)
    allocate(numbers(array_size))

    call fyaml_get_size(config, "coordinates", array_size, RC)
    allocate(coordinates(array_size))

    call fyaml_get_size(config, "names", array_size, RC)
    allocate(names(array_size))

    call fyaml_get_size(config, "flags", array_size, RC)
    allocate(flags(array_size))

    ! Read arrays
    call fyaml_get(config, "numbers", numbers, RC)
    call fyaml_get(config, "coordinates", coordinates, RC)
    call fyaml_get(config, "names", names, RC)
    call fyaml_get(config, "flags", flags, RC)

    ! Display arrays
    write(*,*) "Numbers:", numbers
    write(*,*) "Coordinates:", coordinates
    write(*,*) "Names:", (trim(names(i))//" ", i=1,size(names))
    write(*,*) "Flags:", flags

    call fyaml_cleanup(config)
end program
```

## Advanced: YAML Anchors

FYAML fully supports YAML anchors and merge keys:

### YAML File (`anchors.yml`):
```yaml
# Define reusable settings
defaults: &default_settings
  timeout: 30
  retries: 3
  log_level: "INFO"

# Use anchors in different configurations
production:
  <<: *default_settings  # Merge default settings
  workers: 10
  debug: false

development:
  <<: *default_settings  # Merge default settings
  workers: 1            # Override workers
  debug: true           # Override debug
  log_level: "DEBUG"    # Override log level
```

### Fortran Code:
```fortran
program anchor_example
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, timeout, prod_workers, dev_workers
    character(len=fyaml_StrLen) :: prod_log, dev_log
    logical :: prod_debug, dev_debug

    call fyaml_init("anchors.yml", config, RC=RC)

    ! Both configurations inherit timeout from defaults
    call fyaml_get(config, "production%timeout", timeout, RC)
    write(*,*) "Production timeout:", timeout  ! Prints: 30

    ! But have different worker counts
    call fyaml_get(config, "production%workers", prod_workers, RC)
    call fyaml_get(config, "development%workers", dev_workers, RC)
    write(*,*) "Workers - Prod:", prod_workers, "Dev:", dev_workers

    ! Log levels can be overridden
    call fyaml_get(config, "production%log_level", prod_log, RC)
    call fyaml_get(config, "development%log_level", dev_log, RC)
    write(*,*) "Log levels - Prod:", trim(prod_log), "Dev:", trim(dev_log)

    call fyaml_cleanup(config)
end program
```

## Error Handling Best Practices

Always check return codes for robust applications:

```fortran
program robust_example
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, value
    logical :: exists

    ! Try to load configuration
    call fyaml_init("config.yml", config, RC=RC)
    if (RC /= fyaml_Success) then
        write(*,*) "ERROR: Cannot load configuration file"
        stop 1
    endif

    ! Check if optional setting exists
    call fyaml_check(config, "optional_setting", exists)
    if (exists) then
        call fyaml_get(config, "optional_setting", value, RC)
        if (RC == fyaml_Success) then
            write(*,*) "Optional setting:", value
        endif
    else
        write(*,*) "Using default for optional_setting"
        value = 42  ! Default value
    endif

    call fyaml_cleanup(config)
end program
```

## Integration with CMake

Add FYAML to your CMake project:

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.12)
project(MyProject Fortran)

# Add FYAML as subdirectory
add_subdirectory(fyaml)

# Create your executable
add_executable(myapp main.f90)

# Link against FYAML
target_link_libraries(myapp fyaml)
target_include_directories(myapp PRIVATE fyaml/build/include)
```

## Next Steps

Now that you have FYAML working, explore these guides:

1. **[Basic Usage](../user-guide/basic-usage.md)** - Detailed API coverage
2. **[Data Types](../user-guide/data-types.md)** - Working with all supported types
3. **[Anchors and Aliases](../user-guide/anchors-aliases.md)** - Advanced YAML features
4. **[Error Handling](../user-guide/error-handling.md)** - Building robust applications
5. **[API Reference](../api/overview.md)** - Complete function documentation

## Common Issues

### Build Problems

**Error**: `gfortran not found`
```bash
# Install gfortran on Ubuntu/Debian
sudo apt-get install gfortran

# Install on macOS with Homebrew
brew install gcc
```

**Error**: `CMake version too old`
```bash
# Update CMake on Ubuntu
sudo apt-get install cmake

# Or download from cmake.org for latest version
```

### Runtime Problems

**Error**: `File not found`
- Ensure YAML file is in the correct working directory
- Use absolute paths for files in other locations
- Check file permissions

**Error**: `Variable not found`
- Verify variable names exactly match YAML content
- Use `fyaml_check()` to test existence
- Check category separators (`%` not `.` or `/`)

### Performance Tips

- Load configuration once at startup, not repeatedly
- Use `fyaml_check()` for optional variables instead of trying and failing
- Call `fyaml_cleanup()` to free memory when done
- For large files, consider splitting into multiple smaller files

## Getting Help

- **Documentation**: Browse the complete [API Reference](../api/overview.md)
- **Examples**: See [Examples](examples.md) for more usage patterns
- **Issues**: Report bugs on [GitHub Issues](https://github.com/your-username/fyaml/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/your-username/fyaml/discussions)
