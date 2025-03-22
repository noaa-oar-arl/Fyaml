# fyaml - A Modern Fortran YAML Parser

A feature-rich YAML parser written in modern Fortran, supporting complex data structures and designed for scientific computing applications.

## Key Features

- **Comprehensive YAML Support**
  - Full support for YAML 1.2 specification
  - Multi-document processing
  - Complex nested structures
  - Sequence and mapping support

- **Rich Data Type Support**
  - Strings, integers, floats (single/double precision)
  - Booleans with multiple formats (true/false, yes/no, on/off)
  - Date and time parsing
  - Null values
  - Multi-line strings

- **Advanced Features**
  - Dot notation for nested access (e.g., "config.database.host")
  - Array and sequence iteration
  - Automatic type conversion
  - Memory-safe implementation
  - Error handling with detailed messages

## Requirements

- Fortran 2008 compliant compiler (gfortran 8.0+ or ifort 19.0+)
- CMake 3.12+
- `fpm` 0.10.1+

## Installation

```bash
git clone https://github.com/yourusername/fyaml.git
cd fyaml
mkdir build && cd build
cmake ..
make
make install
```

### Installing with `fpm`

To build `Fyaml` with the [Fortran Package Manager](https://fpm.fortran-lang.org/), add the following to your project's `fpm.toml`:

```toml
[dependencies]
fyaml = { git="git@github.com:noaa-oar-arl/Fyaml.git", branch = "main" }
```

Then, `fpm build`.

## Usage Examples

1) Create a complex YAML configuration:

```yaml
simulation:
  parameters:
    timestep: 0.01
    max_iterations: 1000
    tolerances:
      - 1.0e-6
      - 1.0e-8
  output:
    format: netcdf
    variables: [temperature, pressure, velocity]
    frequency: 100
```

2) Parse and access data:

```fortran
program simulation_setup
    use fyaml

    type(fyaml_doc) :: config
    type(yaml_value) :: val
    real(dp) :: timestep
    character(len=:), allocatable, dimension(:) :: variables

    ! Load configuration
    call config%load("simulation.yaml")

    ! Get scalar values using dot notation
    timestep = config%get("simulation.parameters.timestep")%get_real()

    ! Get array of strings
    variables = config%get("simulation.output.variables")%get_string_array()

    ! Check if a key exists
    if (config%has_key("simulation.output.format")) then
        print *, "Output format:", config%get("simulation.output.format")%get_str()
    end if
end program
```

3) Working with sequences and mappings:

```fortran
! Iterate over sequence
type(yaml_value) :: tolerances
tolerances = config%get("simulation.parameters.tolerances")
if (tolerances%is_sequence()) then
    do i = 1, tolerances%size()
        print *, "Tolerance", i, ":", tolerances%get(i)%get_real()
    end do
end if
```

4) Getting all keys from a YAML document:

```yaml
# Example configuration
database:
  host: localhost
  port: 5432
logging:
  level: debug
  file: app.log
```

```fortran
program key_example
    use fyaml

    type(fyaml_doc) :: config
    type(yaml_value) :: root_value, db_value
    character(len=:), allocatable, dimension(:) :: root_keys, db_keys

    ! Load configuration
    call config%load("config.yaml")

    ! Get all root level keys
    root_value = config%root
    root_keys = root_value%get_keys()
    print *, "Root level keys:", root_keys  ! Will print: database, logging

    ! Get keys from nested section
    db_value = config%get("database")
    db_keys = db_value%get_keys()
    print *, "Database keys:", db_keys  ! Will print: host, port

    ! Check if specific keys exist
    if (root_value%has_key("database")) then
        print *, "Database configuration found!"
    end if
end program
```

## Error Handling

```fortran
logical :: success
character(len=:), allocatable :: error_msg

call config%load("config.yaml", success, error_msg)
if (.not. success) then
    print *, "Error loading YAML:", error_msg
    error stop
end if
```

## Testing
```bash
ctest --test-dir build/tests --output-on-failure
```

## Documentation
Documentation is generated using FORD. To build:

```bash
ford docs.md
```

## License
GNU General Public License v3.0

## Contributing
Contributions welcome! Please read CONTRIBUTING.md for guidelines.

## Disclaimer
The United States Department of Commerce (DOC) GitHub project code is
provided on an 'as is' basis and the user assumes responsibility for
its use.  DOC has relinquished control of the information and no
longer has responsibility to protect the integrity, confidentiality,
or availability of the information.  Any claims against the Department
of Commerce stemming from the use of its GitHub project will be
governed by all applicable Federal law.  Any reference to specific
commercial products, processes, or services by service mark,
trademark, manufacturer, or otherwise, does not constitute or imply
their endorsement, recommendation or favoring by the Department of
Commerce.  The Department of Commerce seal and logo, or the seal and
logo of a DOC bureau, shall not be used in any manner to imply
endorsement of any commercial product or activity by DOC or the United
States Government.
