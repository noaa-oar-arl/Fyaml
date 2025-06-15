# Categories

FYAML provides support for organizing data using categories, which is especially useful for scientific applications that need to classify and group related data.

## Understanding Categories in YAML

Categories in FYAML represent a convenient way to group and classify data within your YAML configuration. They provide a hierarchical organization that helps manage complex data structures.

## Basic Category Usage

Here's a simple example of using categories in YAML:

```yaml
categories:
  physics:
    - name: mechanics
      description: Classical mechanics and dynamics
      priority: high
    - name: thermodynamics
      description: Study of heat and energy
      priority: medium
    - name: electromagnetism
      description: Study of electrical and magnetic phenomena
      priority: high

  chemistry:
    - name: organic
      description: Chemistry of carbon compounds
      priority: high
    - name: inorganic
      description: Chemistry of non-carbon compounds
      priority: medium
    - name: analytical
      description: Techniques for chemical analysis
      priority: low
```

## Parsing Categories

FYAML handles categories similar to other nested structures:

```fortran
use fyaml

type(fyaml_config) :: config
integer :: num_physics_categories, num_chemistry_categories
character(len=:), allocatable :: category_name, description
character(len=:), allocatable :: priority
logical :: status

! Parse the YAML file
status = fyaml_parse_file(config, "categories.yml")

! Get the number of categories in each group
status = fyaml_get_size(config, "categories.physics", num_physics_categories)
status = fyaml_get_size(config, "categories.chemistry", num_chemistry_categories)

! Access physics categories
print *, "Physics categories:", num_physics_categories
do i = 1, num_physics_categories
    status = fyaml_get(config, "categories.physics[" // trim(to_string(i-1)) // "].name", category_name)
    status = fyaml_get(config, "categories.physics[" // trim(to_string(i-1)) // "].description", description)
    status = fyaml_get(config, "categories.physics[" // trim(to_string(i-1)) // "].priority", priority)

    print *, "Category:", category_name
    print *, "Description:", description
    print *, "Priority:", priority
    print *, ""
end do
```

## Category Hierarchies

Categories can be nested to create hierarchies:

```yaml
science:
  physics:
    mechanics:
      - name: classical
        topics: [Newton's laws, kinematics, dynamics]
      - name: relativistic
        topics: [special relativity, general relativity]
    quantum:
      - name: quantum mechanics
        topics: [wave functions, operators, measurements]
      - name: quantum field theory
        topics: [particle physics, quantum electrodynamics]
```

Accessing nested categories:

```fortran
character(len=:), allocatable :: topic_list
integer :: num_topics

! Get number of categories in classical mechanics
status = fyaml_get_size(config, "science.physics.mechanics[0].topics", num_topics)

! Get topic list as a string
status = fyaml_get(config, "science.physics.mechanics[0].topics", topic_list)
print *, "Classical mechanics topics:", topic_list
```

## Category Filtering

FYAML provides utilities to filter and search through categories:

```fortran
use fyaml
use fyaml_utils

type(fyaml_config) :: config
type(fyaml_config) :: filtered_config
logical :: status

! Parse the configuration file
status = fyaml_parse_file(config, "categories.yml")

! Filter categories with "high" priority
status = fyaml_filter_by_property(config, filtered_config, &
                                 "categories..*.priority", "high")

! Work with filtered configuration
call fyaml_print(filtered_config)
```

## Category Merging

Categories from different sources can be merged:

```fortran
use fyaml

type(fyaml_config) :: config1, config2, merged_config
logical :: status

! Parse configuration files
status = fyaml_parse_file(config1, "categories1.yml")
status = fyaml_parse_file(config2, "categories2.yml")

! Merge configurations
status = fyaml_merge(config1, config2, merged_config)

! Work with merged configuration
call fyaml_print(merged_config)
```

## Dynamic Category Creation

Categories can be created or modified dynamically:

```fortran
use fyaml

type(fyaml_config) :: config
logical :: status

! Start with an empty configuration
call fyaml_init(config)

! Add categories
status = fyaml_add(config, "categories.biology[0].name", "genetics")
status = fyaml_add(config, "categories.biology[0].description", "Study of genes and heredity")
status = fyaml_add(config, "categories.biology[0].priority", "high")

status = fyaml_add(config, "categories.biology[1].name", "ecology")
status = fyaml_add(config, "categories.biology[1].description", "Study of organism interactions")
status = fyaml_add(config, "categories.biology[1].priority", "medium")

! Write to file
status = fyaml_write_file(config, "biology_categories.yml")
```

## Category Validation

You can validate that categories meet expected criteria:

```fortran
use fyaml
use fyaml_validator

type(fyaml_config) :: config
type(fyaml_config) :: schema
type(fyaml_error_type) :: error
logical :: status

! Parse the configuration and schema files
status = fyaml_parse_file(config, "categories.yml")
status = fyaml_parse_file(schema, "category_schema.yml")

! Validate configuration against schema
status = fyaml_validate(config, schema, error)
if (.not. status) then
    print *, "Validation error:", error%message
end if
```

## Best Practices

1. **Consistent Structure**: Maintain a consistent structure across categories for easier processing
2. **Meaningful Names**: Use descriptive names for categories and their properties
3. **Appropriate Nesting**: Don't nest categories too deeply to maintain readability
4. **Documentation**: Add descriptions to categories to clarify their purpose
5. **Validation**: Use schema validation to ensure category data meets your requirements

For more details on category handling functions, see the [API Reference](../api/fyaml.md).
