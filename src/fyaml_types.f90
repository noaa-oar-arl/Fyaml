!> \file fyaml_types.f90
!! \brief Type definitions for FYAML
!!
!! This module defines the core data types used in the FYAML library,
!! including the variable type and main configuration type.
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml_types
    use fyaml_precision, only: yp
    use fyaml_constants
    implicit none
    private

    public :: fyaml_var_t, fyaml_t

    !> \brief Type for a single variable
    !!
    !! This type represents a single YAML variable with all its metadata
    !! and data storage capabilities.
    type :: fyaml_var_t
        character(len=fyaml_NamLen)              :: category
        character(len=fyaml_NamLen)              :: var_name
        character(len=fyaml_StrLen)              :: description
        integer                                   :: var_type
        integer                                   :: var_size
        logical                                   :: dynamic_size
        logical                                   :: used
        integer                                   :: set_by = fyaml_set_by_default
        character(len=fyaml_maxDataLen)          :: stored_data
        character(len=fyaml_NamLen)              :: anchor_ptr
        character(len=fyaml_NamLen)              :: anchor_tgt
        real(yp),                     allocatable :: real_data(:)
        integer,                      allocatable :: int_data(:)
        character(len=fyaml_StrLen), allocatable :: char_data(:)
        logical,                      allocatable :: bool_data(:)
    end type fyaml_var_t

    !> \brief Type for the list of variables
    !!
    !! This is the main type that contains all YAML variables and
    !! metadata about the configuration.
    type :: fyaml_t
        logical                                   :: sorted = .false.
        integer                                   :: num_vars = 0
        type(fyaml_var_t),           allocatable :: vars(:)
    end type fyaml_t

end module fyaml_types
