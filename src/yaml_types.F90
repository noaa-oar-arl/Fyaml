!> \brief Core YAML type definitions
!>
!> \details Defines the fundamental types needed for YAML parsing.
!> These types form the backbone of the document structure.
!>
!> \private
module yaml_types
    implicit none
    private
    public :: yaml_node, yaml_document, copy_anchor_type_to_alias

    !> \brief Core node type for YAML elements
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

        ! Anchor/alias support
        character(len=:), allocatable :: anchor      !< Anchor name if node is anchored
        character(len=:), allocatable :: alias_name  !< Name of referenced anchor if is_alias=.true.
        type(yaml_node), pointer :: anchor_target => null() !< Points to referenced anchor node
        logical :: is_alias = .false.  !< True if node is an alias reference
        logical :: is_merged = .false. !< True if node is a merged reference (<<)
    end type yaml_node

    !> \brief Document container type
    type :: yaml_document
        type(yaml_node), pointer :: root => null() !< Root node
    end type yaml_document

    ! Remove yaml_error type - handle errors through status codes

    !> \brief Interface to copy anchor node type information to alias nodes
    interface copy_anchor_type_to_alias
        module procedure :: copy_anchor_type_to_alias_impl
    end interface

contains

    !> \brief Copy type information from an anchor node to an alias node
    !> \param[in,out] alias_node The alias node to update
    !> \param[in] anchor_node The anchor node to copy from
    subroutine copy_anchor_type_to_alias_impl(alias_node, anchor_node)
        type(yaml_node), intent(inout) :: alias_node
        type(yaml_node), intent(in) :: anchor_node

        ! Copy type flags from anchor to alias
        alias_node%is_sequence = anchor_node%is_sequence
        alias_node%is_null = anchor_node%is_null
        alias_node%is_boolean = anchor_node%is_boolean
        alias_node%is_integer = anchor_node%is_integer
        alias_node%is_float = anchor_node%is_float
        alias_node%is_string = anchor_node%is_string

        ! Don't copy is_root - an alias can't be a root node
        ! Don't copy is_alias/is_merged - these are properties of the alias itself
    end subroutine copy_anchor_type_to_alias_impl

end module yaml_types
