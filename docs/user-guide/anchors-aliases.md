# Anchors and Aliases

One of FYAML's powerful features is its comprehensive support for YAML anchors and aliases, which allow for reusing content and creating more maintainable configuration files.

## Understanding Anchors and Aliases

In YAML:
- **Anchors** (&) define a reusable piece of content
- **Aliases** (*) reference previously defined anchors
- **Merge keys** (<<:) can incorporate entire maps

## Basic Anchor and Alias Usage

Here's a simple example of anchors and aliases in YAML:

```yaml
defaults: &defaults
  timeout: 30
  retry: 3
  logging: true

service1:
  <<: *defaults  # Merges all key-value pairs from 'defaults'
  port: 8080
  name: "API Service"

service2:
  <<: *defaults  # Reuses the same defaults
  port: 9090
  name: "Admin Service"
```

In this example, both `service1` and `service2` inherit all properties from `defaults`.

## Parsing Files with Anchors and Aliases

FYAML handles anchors and aliases transparently:

```fortran
use fyaml

type(fyaml_config) :: config
logical :: status
integer :: timeout1, timeout2
integer :: port1, port2

! Parse file with anchors and aliases
status = fyaml_parse_file(config, "services.yml")

! Access the merged properties
status = fyaml_get(config, "service1.timeout", timeout1)
status = fyaml_get(config, "service1.port", port1)
status = fyaml_get(config, "service2.timeout", timeout2)
status = fyaml_get(config, "service2.port", port2)

! These will print the same timeout value
print *, "Service 1 timeout:", timeout1  ! 30
print *, "Service 2 timeout:", timeout2  ! 30

! These will print different port values
print *, "Service 1 port:", port1  ! 8080
print *, "Service 2 port:", port2  ! 9090
```

## Complex Anchor Scenarios

### Nested Anchors

FYAML supports nested anchors and partial merging:

```yaml
database: &db
  driver: postgres
  settings: &db_settings
    pool: 5
    timeout: 60

production:
  database:
    <<: *db
    host: prod-db.example.com
    settings:
      <<: *db_settings
      pool: 20  # Override just this setting
```

Accessing nested merged properties:

```fortran
character(len=:), allocatable :: driver, host
integer :: pool, timeout

! Access properties with merged anchors
status = fyaml_get(config, "production.database.driver", driver)
status = fyaml_get(config, "production.database.host", host)
status = fyaml_get(config, "production.database.settings.pool", pool)
status = fyaml_get(config, "production.database.settings.timeout", timeout)

print *, "Driver:", driver     ! postgres
print *, "Host:", host         ! prod-db.example.com
print *, "Pool:", pool         ! 20 (overridden)
print *, "Timeout:", timeout   ! 60 (from anchor)
```

### Array Anchors

Anchors can also be used with arrays:

```yaml
base_plugins: &base
  - logger
  - security
  - cache

development:
  plugins:
    - *base
    - debugger
    - profiler

production:
  plugins:
    - *base
    - metrics
    - load_balancer
```

This is parsed slightly differently:

```fortran
integer :: num_plugins
character(len=:), allocatable :: plugin_name

! Get the number of plugins for development
status = fyaml_get_size(config, "development.plugins", num_plugins)
print *, "Development plugins:", num_plugins

! Access plugin names
do i = 1, num_plugins
    status = fyaml_get(config, "development.plugins[" // trim(to_string(i-1)) // "]", plugin_name)
    print *, "Plugin", i, ":", plugin_name
end do
```

## Advanced Anchor Features

### Multiple Merges

YAML allows multiple anchors to be merged into a single map:

```yaml
defaults: &defaults
  timeout: 30
  retry: 3

logging: &logging
  log_level: info
  log_file: app.log

service:
  <<: [*defaults, *logging]
  name: "Combined Service"
```

FYAML handles these complex merges correctly:

```fortran
character(len=:), allocatable :: log_level
integer :: timeout

status = fyaml_get(config, "service.timeout", timeout)
status = fyaml_get(config, "service.log_level", log_level)

print *, "Timeout:", timeout     ! 30
print *, "Log level:", log_level ! info
```

### Overriding Precedence

When merging anchors, later keys override earlier ones:

```yaml
base: &base
  setting: "default"
  option: "base"

override: &override
  option: "override"
  new_option: "added"

result:
  <<: [*base, *override]  # override takes precedence for duplicated keys
```

## Best Practices

1. **Use Anchors for Common Patterns**: Identify repeated configurations and define them as anchors.
2. **Meaningful Anchor Names**: Use descriptive names for anchors to improve readability.
3. **Document Anchor Usage**: Comment your YAML files to make anchor usage clear.
4. **Avoid Deep Nesting**: While FYAML supports deeply nested anchors, keep your structure reasonably flat for maintainability.
5. **Test Complex Merges**: Verify that complex anchor and alias configurations are parsed as expected.

## Debugging Anchor Issues

If you encounter issues with anchors and aliases, FYAML provides debugging capabilities:

```fortran
! Enable verbose mode
call fyaml_set_verbose(.true.)

! Parse the file
status = fyaml_parse_file(config, "complex_anchors.yml")

! Print the resolved configuration (with all anchors expanded)
call fyaml_print(config)
```

For more details on anchor-related functions, see the [API Reference](../api/fyaml.md).
