!> Core YAML type definitions
!!
!! Defines the fundamental types needed for YAML parsing.
!! These types form the backbone of the document structure.
!!
!! @private
module yaml_types
    implicit none
    private
    public :: yaml_node, yaml_document

    !> Core node type for YAML elements
    type :: yaml_node
        character(len=:), allocatable :: key    !< Node key name
        character(len=:), allocatable :: value  !< Node value content
        type(yaml_node), pointer :: children => null() !< Child nodes
        type(yaml_node), pointer :: next => null()    !< Next sibling
        type(yaml_node), pointer :: parent => null()  !< Parent node
        integer :: indent = 0  !< Indentation level
        integer :: line_num = 0 !< Line number in source file where node appeared
        integer :: last_child_line = 0 !< Line number of last processed child
        logical :: is_sequence = .false.  !< Sequence flag
        logical :: is_null = .false.      !< Null value flag
        logical :: is_boolean = .false.   !< Boolean flag
        logical :: is_integer = .false.   !< Integer flag
        logical :: is_float = .false.     !< Float flag
        logical :: is_string = .true.     !< String flag (default)
        logical :: is_root = .false.      !< Root node flag (replaces is_root_key)
    end type yaml_node

    !> Document container type
    type :: yaml_document
        type(yaml_node), pointer :: root => null() !< Root node
    end type yaml_document

    ! Remove yaml_error type - handle errors through status codes
end module yaml_types
