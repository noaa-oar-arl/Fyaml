# Parser Internals

This page provides an overview of FYAML's parser internals, which are useful for advanced users who need to extend the parser functionality or understand how YAML documents are processed.

## Parser Architecture

The FYAML parser follows a multi-stage approach to processing YAML documents:

1. **Lexical Analysis**: Converting the input stream into tokens
2. **Syntax Analysis**: Building a parse tree from tokens
3. **Document Construction**: Creating a document object from the parse tree
4. **Resolution**: Resolving anchors, aliases, and references

## Parser Modules

The parser functionality is spread across several modules:

- `fyaml_parser.f90`: Main parser implementation
- `fyaml_parser_new.f90`: Enhanced parser with additional features
- `fyaml_lexer.f90` (internal): Lexical analyzer for YAML tokens

## YAML Parsing Process

### 1. Lexical Analysis

The lexer breaks down the YAML document into tokens such as:

- Scalar values (strings, numbers, booleans)
- Structure indicators (dash `-` for sequences, colon `:` for mappings)
- Block delimiters (indentation)
- Special directives and tags

```fortran
! Example of internal lexer usage (not typically used directly)
use fyaml_parser, only: fyaml_lexer_type
type(fyaml_lexer_type) :: lexer
logical :: status

status = lexer%initialize("input.yaml")
do while (lexer%has_next())
    call lexer%next_token()
    ! Process token
end do
```

### 2. Syntax Analysis

The parser consumes tokens from the lexer and builds a syntax tree according to the YAML specification:

- Handles indentation-based hierarchy
- Validates document structure
- Processes document directives
- Recognizes scalar formats (quoted, folded, literal, etc.)

### 3. Document Construction

After parsing, FYAML constructs an in-memory representation of the YAML document:

- Creates nodes for each YAML element
- Builds the hierarchy of maps and sequences
- Processes and stores anchors for later reference

### 4. Anchor Resolution

FYAML's robust anchor resolution system:

- Tracks all anchors in the document
- Resolves aliases when referenced
- Handles merge keys (`<<:`) for maps
- Detects and prevents circular references

## Customizing the Parser

Advanced users can customize parser behavior:

```fortran
use fyaml
use fyaml_parser

type(fyaml_config) :: config
type(fyaml_parser_options) :: options

! Configure parser options
options%allow_duplicate_keys = .false.
options%strict_indentation = .true.
options%max_depth = 100

! Parse with custom options
status = fyaml_parse_file_with_options(config, "input.yaml", options)
```

## Error Handling

The parser provides detailed error information:

```fortran
use fyaml
use fyaml_error

type(fyaml_config) :: config
type(fyaml_error_type) :: error
logical :: status

status = fyaml_parse_file(config, "input.yaml", error)
if (.not. status) then
    print *, "Error at line ", error%line, ", column ", error%column
    print *, "Message: ", error%message
end if
```

## Performance Considerations

The FYAML parser is designed for efficiency but has some considerations:

- **Document Size**: Very large documents (>10MB) may impact performance
- **Anchor Resolution**: Complex anchor structures can increase parsing time
- **Memory Usage**: The parser maintains the entire document in memory

## Debugging the Parser

For debugging purposes, FYAML provides tracing capabilities:

```fortran
! Enable parser tracing
call fyaml_set_trace_level(FYAML_TRACE_DETAILED)

! Parse with tracing enabled
status = fyaml_parse_file(config, "input.yaml")

! Disable tracing when done
call fyaml_set_trace_level(FYAML_TRACE_NONE)
```

## Extending the Parser

Advanced users can extend the parser by:

1. Creating custom scalar processors
2. Implementing specialized tag handlers
3. Adding validation hooks

See the [Contributing](../developer/contributing.md) guide for more information on extending FYAML's capabilities.

## Related API Documentation

For more details, see the generated API documentation for the parser modules:

- [Parser Types and Constants](../api/types.md)
- [Core FYAML Module](../fyaml/namespacefyaml.md)
