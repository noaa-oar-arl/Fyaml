# Examples

This page provides comprehensive examples of using FYAML in real-world scenarios. Each example includes both the YAML configuration and the corresponding Fortran code.

## Basic Examples

### Example 1: Simple Configuration

The most basic use case - loading simple key-value pairs.

#### Configuration File (`simple.yml`)

```yaml
# Simple application configuration
app_name: "Weather Simulator"
version: 2.1
debug_mode: false
max_iterations: 1000
output_frequency: 100
tolerance: 1.0e-6
```

#### Fortran Code

```fortran
program simple_config
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC

    ! Configuration variables
    character(len=fyaml_StrLen) :: app_name
    real(yp) :: version, tolerance
    logical :: debug_mode
    integer :: max_iterations, output_frequency

    ! Load configuration
    call fyaml_init("simple.yml", config, RC=RC)
    if (RC /= fyaml_Success) then
        write(*,*) "Error loading configuration"
        stop 1
    endif

    ! Read all values
    call fyaml_get(config, "app_name", app_name, RC)
    call fyaml_get(config, "version", version, RC)
    call fyaml_get(config, "debug_mode", debug_mode, RC)
    call fyaml_get(config, "max_iterations", max_iterations, RC)
    call fyaml_get(config, "output_frequency", output_frequency, RC)
    call fyaml_get(config, "tolerance", tolerance, RC)

    ! Use configuration
    write(*,*) "Starting", trim(app_name), "version", version
    if (debug_mode) write(*,*) "Debug mode enabled"
    write(*,*) "Will run", max_iterations, "iterations"

    call fyaml_cleanup(config)
end program simple_config
```

### Example 2: Nested Configuration

Working with hierarchical configurations using categories.

#### Configuration File (`nested.yml`)

```yaml
# Nested configuration example
application:
  name: "Scientific Simulation"
  version: "3.0.1"
  author: "Research Team"

simulation:
  physics:
    gravity: 9.81
    friction: 0.1
    air_resistance: true

  numerics:
    timestep: 0.001
    tolerance: 1.0e-8
    max_iterations: 50000

  output:
    format: "HDF5"
    precision: "double"
    compress: true

computational:
  threads: 8
  memory_limit: "4GB"
  use_gpu: false
```

#### Fortran Code

```fortran
program nested_config
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC

    ! Application info
    character(len=fyaml_StrLen) :: app_name, version, author

    ! Physics parameters
    real(yp) :: gravity, friction
    logical :: air_resistance

    ! Numerical parameters
    real(yp) :: timestep, tolerance
    integer :: max_iterations

    ! Output settings
    character(len=fyaml_StrLen) :: output_format, precision
    logical :: compress

    ! Computational settings
    integer :: threads
    character(len=fyaml_StrLen) :: memory_limit
    logical :: use_gpu

    call fyaml_init("nested.yml", config, RC=RC)
    if (RC /= fyaml_Success) stop 1

    ! Read application info
    call fyaml_get(config, "application%name", app_name, RC)
    call fyaml_get(config, "application%version", version, RC)
    call fyaml_get(config, "application%author", author, RC)

    ! Read physics parameters
    call fyaml_get(config, "simulation%physics%gravity", gravity, RC)
    call fyaml_get(config, "simulation%physics%friction", friction, RC)
    call fyaml_get(config, "simulation%physics%air_resistance", air_resistance, RC)

    ! Read numerical parameters
    call fyaml_get(config, "simulation%numerics%timestep", timestep, RC)
    call fyaml_get(config, "simulation%numerics%tolerance", tolerance, RC)
    call fyaml_get(config, "simulation%numerics%max_iterations", max_iterations, RC)

    ! Read output settings
    call fyaml_get(config, "simulation%output%format", output_format, RC)
    call fyaml_get(config, "simulation%output%precision", precision, RC)
    call fyaml_get(config, "simulation%output%compress", compress, RC)

    ! Read computational settings
    call fyaml_get(config, "computational%threads", threads, RC)
    call fyaml_get(config, "computational%memory_limit", memory_limit, RC)
    call fyaml_get(config, "computational%use_gpu", use_gpu, RC)

    ! Display configuration summary
    write(*,*) "=== Configuration Summary ==="
    write(*,*) "Application:", trim(app_name), "v", trim(version)
    write(*,*) "Author:", trim(author)
    write(*,*) "Gravity:", gravity, "m/s²"
    write(*,*) "Timestep:", timestep, "s"
    write(*,*) "Max iterations:", max_iterations
    write(*,*) "Output format:", trim(output_format)
    write(*,*) "Threads:", threads
    if (use_gpu) write(*,*) "GPU acceleration: enabled"

    call fyaml_cleanup(config)
end program nested_config
```

### Example 3: Working with Arrays

Handling lists and arrays in YAML configurations.

#### Configuration File (`arrays.yml`)

```yaml
# Array examples
mesh:
  dimensions: [100, 200, 50]
  spacing: [0.1, 0.05, 0.2]

boundary_conditions:
  types: ["periodic", "fixed", "open"]
  values: [0.0, 1.0, 0.0]

materials:
  names: ["steel", "aluminum", "copper"]
  densities: [7850.0, 2700.0, 8960.0]
  elastic_moduli: [200.0e9, 70.0e9, 110.0e9]

processing:
  enabled_modules: [true, false, true, true]
  module_weights: [1.0, 0.5, 2.0, 1.5]

coordinates:
  x_points: [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
  y_points: [0.0, 0.5, 1.0, 1.5, 2.0]
```

#### Fortran Code

```fortran
program array_config
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, i, array_size

    ! Array variables
    integer, allocatable :: dimensions(:)
    real(yp), allocatable :: spacing(:), densities(:), elastic_moduli(:)
    real(yp), allocatable :: values(:), module_weights(:)
    real(yp), allocatable :: x_points(:), y_points(:)
    character(len=fyaml_StrLen), allocatable :: types(:), material_names(:)
    logical, allocatable :: enabled_modules(:)

    call fyaml_init("arrays.yml", config, RC=RC)
    if (RC /= fyaml_Success) stop 1

    ! Get mesh dimensions
    call fyaml_get_size(config, "mesh%dimensions", array_size, RC)
    allocate(dimensions(array_size))
    call fyaml_get(config, "mesh%dimensions", dimensions, RC)

    call fyaml_get_size(config, "mesh%spacing", array_size, RC)
    allocate(spacing(array_size))
    call fyaml_get(config, "mesh%spacing", spacing, RC)

    ! Get boundary conditions
    call fyaml_get_size(config, "boundary_conditions%types", array_size, RC)
    allocate(types(array_size))
    call fyaml_get(config, "boundary_conditions%types", types, RC)

    call fyaml_get_size(config, "boundary_conditions%values", array_size, RC)
    allocate(values(array_size))
    call fyaml_get(config, "boundary_conditions%values", values, RC)

    ! Get material properties
    call fyaml_get_size(config, "materials%names", array_size, RC)
    allocate(material_names(array_size))
    allocate(densities(array_size))
    allocate(elastic_moduli(array_size))

    call fyaml_get(config, "materials%names", material_names, RC)
    call fyaml_get(config, "materials%densities", densities, RC)
    call fyaml_get(config, "materials%elastic_moduli", elastic_moduli, RC)

    ! Get processing settings
    call fyaml_get_size(config, "processing%enabled_modules", array_size, RC)
    allocate(enabled_modules(array_size))
    allocate(module_weights(array_size))

    call fyaml_get(config, "processing%enabled_modules", enabled_modules, RC)
    call fyaml_get(config, "processing%module_weights", module_weights, RC)

    ! Get coordinates
    call fyaml_get_size(config, "coordinates%x_points", array_size, RC)
    allocate(x_points(array_size))
    call fyaml_get(config, "coordinates%x_points", x_points, RC)

    call fyaml_get_size(config, "coordinates%y_points", array_size, RC)
    allocate(y_points(array_size))
    call fyaml_get(config, "coordinates%y_points", y_points, RC)

    ! Display results
    write(*,*) "=== Mesh Configuration ==="
    write(*,*) "Dimensions:", dimensions
    write(*,*) "Spacing:", spacing

    write(*,*) "=== Boundary Conditions ==="
    do i = 1, size(types)
        write(*,*) "BC", i, ":", trim(types(i)), "=", values(i)
    end do

    write(*,*) "=== Materials ==="
    do i = 1, size(material_names)
        write(*,*) trim(material_names(i)), ":"
        write(*,*) "  Density:", densities(i), "kg/m³"
        write(*,*) "  Elastic modulus:", elastic_moduli(i), "Pa"
    end do

    write(*,*) "=== Processing Modules ==="
    do i = 1, size(enabled_modules)
        write(*,*) "Module", i, ": enabled =", enabled_modules(i), &
                   ", weight =", module_weights(i)
    end do

    write(*,*) "=== Coordinate Points ==="
    write(*,*) "X points:", x_points
    write(*,*) "Y points:", y_points

    call fyaml_cleanup(config)
end program array_config
```

## Advanced Examples

### Example 4: YAML Anchors and Inheritance

Demonstrating the power of YAML anchors for configuration reuse.

#### Configuration File (`anchors.yml`)

```yaml
# Define reusable configurations with anchors
database_defaults: &db_defaults
  host: "localhost"
  port: 5432
  timeout: 30
  ssl: true
  pool_size: 10
  retry_attempts: 3

solver_defaults: &solver_defaults
  tolerance: 1.0e-6
  max_iterations: 1000
  preconditioner: "ILU"
  convergence_check: 10

output_defaults: &output_defaults
  format: "HDF5"
  compression: true
  precision: "double"
  frequency: 100

# Environment-specific configurations
environments:
  development:
    database:
      <<: *db_defaults
      host: "dev.example.com"
      pool_size: 5  # Override for dev

    solver:
      <<: *solver_defaults
      tolerance: 1.0e-4  # Relaxed tolerance for dev
      max_iterations: 500

    output:
      <<: *output_defaults
      format: "ASCII"  # Easier debugging
      compression: false

  production:
    database:
      <<: *db_defaults
      host: "prod.example.com"
      port: 5433
      pool_size: 20  # More connections for prod

    solver:
      <<: *solver_defaults
      # Use all defaults for production

    output:
      <<: *output_defaults
      frequency: 1000  # Less frequent output

  testing:
    database:
      <<: *db_defaults
      host: "test.example.com"
      timeout: 10  # Faster timeout for tests

    solver:
      <<: *solver_defaults
      max_iterations: 100  # Quick tests

    output:
      <<: *output_defaults
      format: "JSON"  # Easy validation
```

#### Fortran Code

```fortran
program anchor_config
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC
    character(len=20) :: environment

    ! Database configuration
    character(len=fyaml_StrLen) :: db_host
    integer :: db_port, db_timeout, db_pool_size, db_retry_attempts
    logical :: db_ssl

    ! Solver configuration
    real(yp) :: solver_tolerance
    integer :: solver_max_iterations, solver_convergence_check
    character(len=fyaml_StrLen) :: solver_preconditioner

    ! Output configuration
    character(len=fyaml_StrLen) :: output_format, output_precision
    logical :: output_compression
    integer :: output_frequency

    call fyaml_init("anchors.yml", config, RC=RC)
    if (RC /= fyaml_Success) stop 1

    ! Choose environment (could be command line argument)
    environment = "production"  ! or "development", "testing"

    write(*,*) "Loading configuration for:", environment

    ! Read database configuration for chosen environment
    call fyaml_get(config, "environments%"//trim(environment)//"%database%host", db_host, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%database%port", db_port, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%database%timeout", db_timeout, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%database%ssl", db_ssl, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%database%pool_size", db_pool_size, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%database%retry_attempts", db_retry_attempts, RC)

    ! Read solver configuration
    call fyaml_get(config, "environments%"//trim(environment)//"%solver%tolerance", solver_tolerance, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%solver%max_iterations", solver_max_iterations, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%solver%preconditioner", solver_preconditioner, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%solver%convergence_check", solver_convergence_check, RC)

    ! Read output configuration
    call fyaml_get(config, "environments%"//trim(environment)//"%output%format", output_format, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%output%compression", output_compression, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%output%precision", output_precision, RC)
    call fyaml_get(config, "environments%"//trim(environment)//"%output%frequency", output_frequency, RC)

    ! Display configuration
    write(*,*) "=== Database Configuration ==="
    write(*,*) "Host:", trim(db_host)
    write(*,*) "Port:", db_port
    write(*,*) "Timeout:", db_timeout, "seconds"
    write(*,*) "SSL:", db_ssl
    write(*,*) "Pool size:", db_pool_size
    write(*,*) "Retry attempts:", db_retry_attempts

    write(*,*) "=== Solver Configuration ==="
    write(*,*) "Tolerance:", solver_tolerance
    write(*,*) "Max iterations:", solver_max_iterations
    write(*,*) "Preconditioner:", trim(solver_preconditioner)
    write(*,*) "Convergence check every:", solver_convergence_check, "iterations"

    write(*,*) "=== Output Configuration ==="
    write(*,*) "Format:", trim(output_format)
    write(*,*) "Precision:", trim(output_precision)
    write(*,*) "Compression:", output_compression
    write(*,*) "Output frequency:", output_frequency

    call fyaml_cleanup(config)
end program anchor_config
```

### Example 5: Configuration Merging

Combining multiple configuration files for complex applications.

#### Base Configuration (`base.yml`)

```yaml
application:
  name: "Multi-Physics Simulator"
  version: "4.0"

defaults:
  solver_tolerance: 1.0e-6
  output_frequency: 100
  debug_level: 1

mesh:
  type: "structured"
  dimensions: [100, 100, 100]

physics:
  enable_heat_transfer: true
  enable_fluid_flow: true
  enable_stress_analysis: false
```

#### Environment Override (`production.yml`)

```yaml
defaults:
  debug_level: 0  # No debug output in production
  output_frequency: 1000  # Less frequent output

computational:
  threads: 32
  memory_limit: "64GB"
  use_mpi: true
  nodes: 16

mesh:
  dimensions: [500, 500, 500]  # Higher resolution

physics:
  enable_stress_analysis: true  # Enable for production runs
```

#### Fortran Code

```fortran
program config_merging
    use fyaml
    implicit none

    type(fyaml_t) :: base_config, override_config, merged_config
    integer :: RC

    ! Configuration variables
    character(len=fyaml_StrLen) :: app_name, app_version, mesh_type
    real(yp) :: solver_tolerance
    integer :: output_frequency, debug_level, threads
    integer, allocatable :: mesh_dimensions(:)
    integer :: array_size
    logical :: enable_heat, enable_fluid, enable_stress, use_mpi
    character(len=fyaml_StrLen) :: memory_limit
    integer :: nodes

    ! Load base configuration
    call fyaml_init("base.yml", base_config, RC=RC)
    if (RC /= fyaml_Success) then
        write(*,*) "Error loading base configuration"
        stop 1
    endif

    ! Load override configuration
    call fyaml_init("production.yml", override_config, RC=RC)
    if (RC /= fyaml_Success) then
        write(*,*) "Error loading override configuration"
        stop 1
    endif

    ! Merge configurations (override takes precedence)
    call fyaml_merge(base_config, override_config, merged_config, RC)
    if (RC /= fyaml_Success) then
        write(*,*) "Error merging configurations"
        stop 1
    endif

    ! Read from merged configuration
    call fyaml_get(merged_config, "application%name", app_name, RC)
    call fyaml_get(merged_config, "application%version", app_version, RC)

    call fyaml_get(merged_config, "defaults%solver_tolerance", solver_tolerance, RC)
    call fyaml_get(merged_config, "defaults%output_frequency", output_frequency, RC)
    call fyaml_get(merged_config, "defaults%debug_level", debug_level, RC)

    call fyaml_get(merged_config, "mesh%type", mesh_type, RC)
    call fyaml_get_size(merged_config, "mesh%dimensions", array_size, RC)
    allocate(mesh_dimensions(array_size))
    call fyaml_get(merged_config, "mesh%dimensions", mesh_dimensions, RC)

    call fyaml_get(merged_config, "physics%enable_heat_transfer", enable_heat, RC)
    call fyaml_get(merged_config, "physics%enable_fluid_flow", enable_fluid, RC)
    call fyaml_get(merged_config, "physics%enable_stress_analysis", enable_stress, RC)

    ! Read production-specific settings
    call fyaml_get(merged_config, "computational%threads", threads, RC)
    call fyaml_get(merged_config, "computational%memory_limit", memory_limit, RC)
    call fyaml_get(merged_config, "computational%use_mpi", use_mpi, RC)
    call fyaml_get(merged_config, "computational%nodes", nodes, RC)

    ! Display final configuration
    write(*,*) "=== Merged Configuration ==="
    write(*,*) "Application:", trim(app_name), "v", trim(app_version)
    write(*,*) "Solver tolerance:", solver_tolerance
    write(*,*) "Output frequency:", output_frequency
    write(*,*) "Debug level:", debug_level
    write(*,*) "Mesh type:", trim(mesh_type)
    write(*,*) "Mesh dimensions:", mesh_dimensions
    write(*,*) "Heat transfer:", enable_heat
    write(*,*) "Fluid flow:", enable_fluid
    write(*,*) "Stress analysis:", enable_stress
    write(*,*) "Threads:", threads
    write(*,*) "Memory limit:", trim(memory_limit)
    write(*,*) "MPI enabled:", use_mpi
    write(*,*) "Nodes:", nodes

    ! Cleanup all configurations
    call fyaml_cleanup(base_config)
    call fyaml_cleanup(override_config)
    call fyaml_cleanup(merged_config)
end program config_merging
```

## Error Handling Examples

### Example 6: Robust Error Handling

```fortran
program robust_config
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, max_iter, threads
    real(yp) :: tolerance
    character(len=fyaml_StrLen) :: output_dir
    logical :: exists, debug_mode

    ! Try to load configuration with error handling
    call fyaml_init("simulation.yml", config, RC=RC)
    if (RC /= fyaml_Success) then
        write(*,*) "WARNING: Cannot load simulation.yml, using defaults"

        ! Set default values
        max_iter = 1000
        tolerance = 1.0e-6_yp
        threads = 4
        output_dir = "./output"
        debug_mode = .false.

        ! Continue with defaults
        goto 100
    endif

    ! Required parameters
    call fyaml_get(config, "max_iterations", max_iter, RC)
    if (RC /= fyaml_Success) then
        write(*,*) "ERROR: max_iterations is required"
        call fyaml_cleanup(config)
        stop 1
    endif

    ! Optional parameters with defaults
    call fyaml_check(config, "tolerance", exists)
    if (exists) then
        call fyaml_get(config, "tolerance", tolerance, RC)
        if (RC /= fyaml_Success) tolerance = 1.0e-6_yp
    else
        tolerance = 1.0e-6_yp
        write(*,*) "INFO: Using default tolerance:", tolerance
    endif

    call fyaml_check(config, "threads", exists)
    if (exists) then
        call fyaml_get(config, "threads", threads, RC)
        if (RC /= fyaml_Success) threads = 4
    else
        threads = 4
        write(*,*) "INFO: Using default thread count:", threads
    endif

    call fyaml_check(config, "output_directory", exists)
    if (exists) then
        call fyaml_get(config, "output_directory", output_dir, RC)
        if (RC /= fyaml_Success) output_dir = "./output"
    else
        output_dir = "./output"
        write(*,*) "INFO: Using default output directory:", trim(output_dir)
    endif

    call fyaml_check(config, "debug", exists)
    if (exists) then
        call fyaml_get(config, "debug", debug_mode, RC)
        if (RC /= fyaml_Success) debug_mode = .false.
    else
        debug_mode = .false.
    endif

    call fyaml_cleanup(config)

100 continue

    ! Use configuration
    write(*,*) "=== Final Configuration ==="
    write(*,*) "Max iterations:", max_iter
    write(*,*) "Tolerance:", tolerance
    write(*,*) "Threads:", threads
    write(*,*) "Output directory:", trim(output_dir)
    write(*,*) "Debug mode:", debug_mode

end program robust_config
```

## Performance Examples

### Example 7: Large Configuration Files

For applications with large configuration files, consider these optimization patterns:

```fortran
program large_config
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: RC, i, num_materials
    real(yp), allocatable :: properties(:)
    character(len=fyaml_StrLen), allocatable :: material_names(:)
    logical :: exists

    ! Load large configuration
    call fyaml_init("large_config.yml", config, RC=RC)
    if (RC /= fyaml_Success) stop 1

    ! Check if materials section exists
    call fyaml_check(config, "materials", exists)
    if (.not. exists) then
        write(*,*) "No materials section found"
        call fyaml_cleanup(config)
        return
    endif

    ! Dynamically determine number of materials
    num_materials = 0
    do i = 1, 1000  ! Reasonable upper limit
        write(material_key, '("materials%material_", I0, "%name")') i
        call fyaml_check(config, material_key, exists)
        if (exists) then
            num_materials = num_materials + 1
        else
            exit
        endif
    end do

    write(*,*) "Found", num_materials, "materials"

    ! Allocate arrays
    allocate(material_names(num_materials))
    allocate(properties(num_materials))

    ! Read material data efficiently
    do i = 1, num_materials
        write(name_key, '("materials%material_", I0, "%name")') i
        write(prop_key, '("materials%material_", I0, "%density")') i

        call fyaml_get(config, name_key, material_names(i), RC)
        call fyaml_get(config, prop_key, properties(i), RC)

        if (RC /= fyaml_Success) then
            write(*,*) "Warning: Could not read material", i
        endif
    end do

    ! Process materials
    do i = 1, num_materials
        write(*,*) "Material", i, ":", trim(material_names(i)), &
                   "density =", properties(i)
    end do

    call fyaml_cleanup(config)
end program large_config
```

## Next Steps

These examples demonstrate the flexibility and power of FYAML for various configuration management scenarios. To learn more:

1. **[API Reference](../api/overview.md)** - Complete function documentation
2. **[User Guide](../user-guide/basic-usage.md)** - Detailed feature explanations
3. **[Anchors and Aliases](../user-guide/anchors-aliases.md)** - Advanced YAML features
4. **[Error Handling](../user-guide/error-handling.md)** - Robust application development

For more examples and use cases, check the `examples/` directory in the FYAML repository.
