# FYAML - Fortran YAML Parser

FYAML is a modern Fortran library designed to parse YAML (YAML Ain't Markup Language) files with full support for advanced features including:

- **Complete YAML syntax support** - handles mappings, sequences, scalars
- **Anchor and alias support** - full implementation of YAML merge keys (`<<: *anchor`)
- **Type-safe API** - strongly typed interfaces for all data types
- **Comprehensive data types** - integers, reals, strings, booleans, arrays
- **Category-based organization** - hierarchical variable naming
- **Error handling** - detailed error reporting and recovery
- **Modern Fortran** - clean, maintainable code using Fortran 2008+ features

## Key Features

### 🎯 **Full YAML Support**
```yaml
# Anchors and aliases
defaults: &default_settings
  timeout: 30
  retries: 3
  log_level: "INFO"

production_config:
  <<: *default_settings  # Merge anchor
  workers: 10
  debug: false

development_config:
  <<: *default_settings  # Inherit defaults
  log_level: "DEBUG"     # Override specific values
```

### 🔧 **Type-Safe API**
```fortran
program example
    use fyaml
    implicit none

    type(fyaml_t) :: config
    integer :: timeout, workers, RC
    logical :: debug_mode
    character(len=fyaml_StrLen) :: log_level

    ! Parse YAML file
    call fyaml_init("config.yml", config, RC=RC)

    ! Get typed values with error checking
    call fyaml_get(config, "production_config%timeout", timeout, RC)
    call fyaml_get(config, "production_config%workers", workers, RC)
    call fyaml_get(config, "production_config%debug", debug_mode, RC)
    call fyaml_get(config, "development_config%log_level", log_level, RC)

    ! Cleanup
    call fyaml_cleanup(config)
end program
```

### 📊 **Comprehensive Data Types**
- **Scalars**: integers, reals, strings, booleans
- **Arrays**: homogeneous arrays of any supported type
- **Categories**: hierarchical organization with dot notation
- **Dynamic sizing**: automatic array resizing
- **Type inference**: automatic type detection from YAML content

## Quick Start

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/fyaml.git
cd fyaml

# Build with CMake
mkdir build && cd build
cmake ..
make

# Run tests
make test
```

### Basic Usage
```fortran
program quick_start
    use fyaml
    implicit none

    type(fyaml_t) :: yml
    integer :: value, RC

    call fyaml_init("example.yml", yml, RC=RC)
    call fyaml_get(yml, "my_variable", value, RC)
    call fyaml_cleanup(yml)
end program
```

## Documentation Structure

- **[Getting Started](getting-started/installation.md)** - Installation and basic setup
- **[User Guide](user-guide/basic-usage.md)** - Comprehensive usage examples
- **[API Reference](api/overview.md)** - Complete API documentation
- **[Developer Guide](developer/architecture.md)** - Architecture and contribution guidelines

## What Makes FYAML Special?

### ✅ **Production Ready**
- Extensively tested with comprehensive test suite
- Memory-safe with proper cleanup routines
- Error handling for robust applications
- Performance optimized for large files

### ✅ **Standards Compliant**
- YAML 1.2 specification compliance
- Full anchor and alias support
- Proper Unicode handling
- Cross-platform compatibility

### ✅ **Developer Friendly**
- Clear, intuitive API design
- Comprehensive documentation
- Examples and tutorials
- Active community support

## Examples

### Configuration Management
```yaml
# app_config.yml
database: &db_defaults
  host: "localhost"
  port: 5432
  timeout: 30

environments:
  production:
    <<: *db_defaults
    host: "prod.example.com"
    ssl: true

  development:
    <<: *db_defaults
    database: "dev_db"
    debug: true
```

### Scientific Computing
```yaml
# simulation.yml
simulation_parameters: &sim_defaults
  timestep: 0.001
  iterations: 10000
  output_frequency: 100

experiments:
  low_resolution:
    <<: *sim_defaults
    grid_size: [100, 100, 100]

  high_resolution:
    <<: *sim_defaults
    grid_size: [500, 500, 500]
    timestep: 0.0001
```

## Community and Support

- **GitHub**: [Report issues and contribute](https://github.com/your-username/fyaml)
- **Documentation**: Comprehensive guides and API reference
- **Examples**: Real-world usage patterns and best practices

## License

FYAML is released under the MIT License. See [LICENSE](LICENSE) for details.
