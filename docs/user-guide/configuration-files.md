# Configuration Files

FYAML is particularly well-suited for parsing and handling configuration files in YAML format, which is a common use case in scientific and engineering applications.

## Basic Configuration File Structure

A typical YAML configuration file has a hierarchical structure with key-value pairs:

```yaml
# Example configuration file
simulation:
  timestep: 0.001
  max_iterations: 1000
  output_frequency: 10

materials:
  - name: steel
    density: 7850.0
    youngs_modulus: 210e9
  - name: aluminum
    density: 2700.0
    youngs_modulus: 69e9

output:
  format: vtk
  directory: "./results"
  write_intermediate: true
```

## Parsing Configuration Files

FYAML provides straightforward methods to parse configuration files:

```fortran
use fyaml

type(fyaml_config) :: config
logical :: status

! Parse the configuration file
status = fyaml_parse_file(config, "config.yml")
if (.not. status) then
    print *, "Error parsing configuration file"
    stop
end if
```

## Accessing Configuration Values

After parsing, you can access configuration values using the `fyaml_get` interface:

```fortran
real :: timestep
integer :: max_iterations
character(len=:), allocatable :: output_format
logical :: status

! Get scalar values
status = fyaml_get(config, "simulation.timestep", timestep)
status = fyaml_get(config, "simulation.max_iterations", max_iterations)
status = fyaml_get(config, "output.format", output_format)
```

## Complex Configuration Structures

FYAML can handle complex nested structures, including arrays, maps, and combinations of both:

```fortran
! Get array elements
integer :: num_materials
real :: density
character(len=:), allocatable :: material_name

! Get number of materials
status = fyaml_get_size(config, "materials", num_materials)

! Access individual material properties
do i = 1, num_materials
    status = fyaml_get(config, "materials[" // trim(to_string(i-1)) // "].name", material_name)
    status = fyaml_get(config, "materials[" // trim(to_string(i-1)) // "].density", density)

    print *, "Material: ", material_name, ", Density: ", density
end do
```

## Modifying Configuration

You can also modify configuration values in memory:

```fortran
! Update a configuration value
status = fyaml_update(config, "simulation.timestep", 0.002)

! Add a new configuration value
status = fyaml_add(config, "simulation.adaptive_timestep", .true.)
```

## Writing Configuration Files

After modification, you can write the updated configuration back to a file:

```fortran
! Write the modified configuration to a new file
status = fyaml_write_file(config, "updated_config.yml")
```

## Best Practices

1. **Use Dot Notation**: FYAML supports dot notation for accessing nested values, which makes your code more readable.
2. **Check Return Status**: Always check the status returned by FYAML functions to handle errors gracefully.
3. **Default Values**: Provide default values for optional configuration parameters.
4. **Validate Configuration**: Validate that required configuration values exist and have appropriate values.

See the [API Reference](../api/fyaml.md) for detailed information on all available functions for working with configuration files.
