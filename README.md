# fyaml - A Modern Fortran YAML Parser

A feature-rich YAML parser written in modern Fortran, supporting complex data structures and designed for scientific computing applications.

## Key Features

- **Comprehensive YAML Support**
  - Full support for YAML 1.2 specification
  - Multi-document processing
  - Anchors and aliases resolution (does not handle anchors with sequences yet)
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

## Installation

```bash
git clone https://github.com/yourusername/fyaml.git
cd fyaml
mkdir build && cd build
cmake ..
make
make install
```

## Usage Examples

### Basic Loading and Value Access

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

### Error Handling

```fortran
logical :: success
character(len=:), allocatable :: error_msg

call config%load("config.yaml", success, error_msg)
if (.not. success) then
    print *, "Error loading YAML:", error_msg
    error stop
end if
```

### Working with sequences
```fortran
! Flow-style sequences
val = doc%get("company%flow_sequence")
if (val%is_sequence()) then
    ! Get as integer array
    integer, allocatable :: int_array(:)
    int_array = val%get_sequence_int()
    ! [1, 2, 4]
endif

! Get real sequence
val = doc%get("company%flow_sequence_real")
if (val%is_sequence()) then
    ! Get as real array
    real, allocatable :: real_array(:)
    real_array = val%get_sequence_real()
    ! [1.1, -2.2, 3.3]
endif

! Get logical sequence
val = doc%get("company%flow_sequence_logical")
if (val%is_sequence()) then
    ! Get as logical array
    logical, allocatable :: bool_array(:)
    bool_array = val%get_sequence_bool()
    ! [.true., .false., .true.]
endif

! Get string sequence
val = doc%get("company%block_sequence_string")
if (val%is_sequence()) then
    ! Get as string array
    character(len=:), allocatable :: str_array(:)
    str_array = val%get_sequence()
    ! ["three", "four", "five"]
endif
```

### Nested Access
```fortran
! Access deeply nested values
integer :: nested_int
nested_int = doc%get("company%nested%values%integer")%get_int()  ! 42

! Get nested sequence
val = doc%get("company%nested%values%sequence")
if (val%is_sequence()) then
    integer, allocatable :: seq(:)
    seq = val%get_sequence_int()  ! [1, 2, 3]
endif

! Access nested mapping
val = doc%get("company%nested%values%mapping%key1")
print *, "Nested value:", val%get_str()  ! "value1"
```

### Working with Multiple Documents
```fortran
! Load multi-document YAML
call doc%load("multi_doc.yaml", success)

! Access specific document
val = doc%get("company%name", doc_index=1)  ! From first document
val = doc%get("deep%nested%values%integer", doc_index=2)  ! From second document

! Get document count
print *, "Number of documents:", doc%n_docs
```

### Exploring Document Structure
```
! Get root level keys
character(len=:), allocatable, dimension(:) :: root_keys
root_keys = doc%root_keys()
do i = 1, size(root_keys)
    print *, "Root key:", root_keys(i)
enddo

! Get child keys of a node
val = doc%get("company")
if (associated(val%node)) then
    character(len=:), allocatable, dimension(:) :: child_keys
    child_keys = val%child_keys()
    do i = 1, size(child_keys)
        print *, "Child key:", child_keys(i)
    enddo
endif
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
