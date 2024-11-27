!> YAML data type definitions module
!!
!! Provides derived type definitions for YAML parsing and representation.
!! Includes node types for building document trees and error handling.
!!
!! @author Barry Baker
!! @version 0.1.0
module yaml_types
  implicit none

  !> Node type representing a single YAML element
  !!
  !! Core type for building YAML document trees. Can represent scalars,
  !! sequences, and mappings with type information and linking.
  type :: yaml_node
    character(len=:), allocatable :: key    !< Node key name
    character(len=:), allocatable :: value  !< Node value content
    type(yaml_node), pointer :: children => null() !< Child nodes for nested structures
    type(yaml_node), pointer :: next => null()     !< Next sibling node in sequence
    logical :: is_sequence = .false.  !< True if node is part of sequence
    logical :: is_null = .false.      !< True if node represents null value
    logical :: is_boolean = .false.   !< True if node contains boolean value
    logical :: is_integer = .false.   !< True if node contains integer value
    logical :: is_float = .false.     !< True if node contains float value
    logical :: is_string = .true.     !< True if node contains string value
  end type yaml_node

  !> Document type containing full YAML structure
  !!
  !! Root container for a YAML document tree. Holds reference to
  !! top-level node and document-wide settings.
  type :: yaml_document
    type(yaml_node), pointer :: root => null() !< Root node of document tree
  end type yaml_document

  !> Error handling type for YAML operations
  !!
  !! Used to track and report errors during YAML processing.
  type :: yaml_error
    logical :: has_error = .false.           !< True if error occurred
    character(len=256) :: message = ''       !< Error message text
  end type yaml_error

end module yaml_types