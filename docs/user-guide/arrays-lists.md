# Arrays and Lists

YAML supports arrays (also called sequences or lists) as a fundamental data type, and FYAML provides comprehensive support for working with these structures.

## YAML Array Syntax

In YAML, arrays can be defined using either block style (with hyphens) or flow style (with square brackets):

### Block Style
```yaml
# Block style array
fruits:
  - apple
  - banana
  - cherry
```

### Flow Style
```yaml
# Flow style array
fruits: [apple, banana, cherry]
```

## Parsing Arrays with FYAML

FYAML can parse both styles of arrays and provides consistent access methods:

```fortran
use fyaml

type(fyaml_config) :: config
integer :: array_size
logical :: status
character(len=:), allocatable :: fruit_name

! Parse the YAML file containing arrays
status = fyaml_parse_file(config, "arrays.yml")

! Get the size of an array
status = fyaml_get_size(config, "fruits", array_size)

! Loop through array elements
do i = 1, array_size
    status = fyaml_get(config, "fruits[" // trim(to_string(i-1)) // "]", fruit_name)
    print *, "Fruit ", i, ": ", fruit_name
end do
```

## Nested Arrays

FYAML can handle nested arrays (arrays within arrays):

```yaml
# Nested arrays
matrix:
  - [1, 2, 3]
  - [4, 5, 6]
  - [7, 8, 9]
```

Accessing nested arrays follows a similar pattern:

```fortran
integer :: num_rows, num_cols
integer :: value

! Get dimensions
status = fyaml_get_size(config, "matrix", num_rows)
status = fyaml_get_size(config, "matrix[0]", num_cols)

! Access elements
do i = 1, num_rows
    do j = 1, num_cols
        status = fyaml_get(config, "matrix[" // trim(to_string(i-1)) // "][" // trim(to_string(j-1)) // "]", value)
        print *, "Matrix(", i, ",", j, ") = ", value
    end do
end do
```

## Arrays of Complex Types

Arrays can contain complex types, such as maps (dictionaries):

```yaml
# Array of objects
people:
  - name: John
    age: 30
    role: Developer
  - name: Alice
    age: 28
    role: Manager
  - name: Bob
    age: 35
    role: Designer
```

Accessing these structures:

```fortran
integer :: num_people
character(len=:), allocatable :: name, role
integer :: age

! Get number of people
status = fyaml_get_size(config, "people", num_people)

! Access individual person's data
do i = 1, num_people
    status = fyaml_get(config, "people[" // trim(to_string(i-1)) // "].name", name)
    status = fyaml_get(config, "people[" // trim(to_string(i-1)) // "].age", age)
    status = fyaml_get(config, "people[" // trim(to_string(i-1)) // "].role", role)

    print *, "Person ", i, ": ", name, ", ", age, ", ", role
end do
```

## Modifying Arrays

FYAML allows you to modify array elements:

```fortran
! Update an array element
status = fyaml_update(config, "fruits[1]", "pineapple")  ! Change banana to pineapple

! Add a new element to an array (requires knowing the current size)
integer :: current_size
status = fyaml_get_size(config, "fruits", current_size)
status = fyaml_add(config, "fruits[" // trim(to_string(current_size)) // "]", "mango")
```

## Creating New Arrays

You can also create new arrays:

```fortran
! Create a new array with initial values
status = fyaml_add(config, "vegetables", "[carrot, broccoli, spinach]")

! Or add elements one by one
status = fyaml_add(config, "numbers[0]", 10)
status = fyaml_add(config, "numbers[1]", 20)
status = fyaml_add(config, "numbers[2]", 30)
```

## Arrays with Anchors and Aliases

FYAML supports YAML's anchor and alias features for arrays:

```yaml
default_settings: &default
  - debug: false
  - verbose: false
  - log_level: info

application_settings:
  <<: *default
  - port: 8080
  - host: localhost
```

See the [Anchors and Aliases](anchors-aliases.md) section for more details on working with these features.

## Best Practices

1. **Zero-based Indexing**: Remember that FYAML uses zero-based indexing for arrays, following the YAML specification.
2. **Check Array Size**: Always check the array size before iterating to avoid out-of-bounds errors.
3. **Error Handling**: Check the status returned by FYAML functions to handle errors gracefully.
4. **Consistent Style**: Choose either block style or flow style for arrays and use it consistently for readability.

For more details on array-related functions, see the [API Reference](../api/fyaml.md).
