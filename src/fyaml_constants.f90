!> \file fyaml_constants.f90
!! \brief Constants and parameters for FYAML
!!
!! This module defines all constants, parameters, and type identifiers
!! used throughout the FYAML library.
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml_constants
    use fyaml_precision, only: yp
    implicit none
    private

    ! Public constants
    public :: fyaml_Success, fyaml_Failure
    public :: fyaml_MaxArr, fyaml_MaxStack, fyaml_NamLen, fyaml_StrLen
    public :: fyaml_MaxDataLen
    public :: fyaml_num_types, fyaml_integer_type, fyaml_real_type
    public :: fyaml_string_type, fyaml_bool_type, fyaml_unknown_type
    public :: fyaml_set_by_default, fyaml_set_by_file
    public :: fyaml_type_names
    public :: tab_char, fyaml_separators, fyaml_brackets
    public :: fyaml_category_separator, unstored_data_string

    ! Success/failure return codes
    integer, parameter :: fyaml_Success        =  0
    integer, parameter :: fyaml_Failure        = -1

    ! Numeric type constants
    integer, parameter :: fyaml_num_types      =  4
    integer, parameter :: fyaml_integer_type   =  1
    integer, parameter :: fyaml_real_type      =  2
    integer, parameter :: fyaml_string_type    =  3
    integer, parameter :: fyaml_bool_type      =  4
    integer, parameter :: fyaml_unknown_type   =  0

    ! How was the YAML file set?
    integer, parameter :: fyaml_set_by_default =  1
    integer, parameter :: fyaml_set_by_file    =  3

    ! Other constants
    integer, parameter :: fyaml_MaxStack       =  20    ! Max cat_stack size
    integer, parameter :: fyaml_NamLen         =  100   ! Max len for names
    integer, parameter :: fyaml_StrLen         =  512   ! Max len for strings
    integer, parameter :: fyaml_MaxArr         =  1000  ! Max entries per array
    integer, parameter :: fyaml_MaxDataLen     =  20000 ! Max stored data size

    character(len=7), parameter :: fyaml_type_names(0:fyaml_num_types) = &
        (/ 'storage', 'integer', 'real   ', 'string ', 'bool   ' /)

    ! The separator(s) for array-like variables (space, comma, ', ", and tab)
    character,         parameter :: tab_char = char(9)
    character(len=*),  parameter :: fyaml_separators = " ,'"""//tab_char

    ! Bracket characters
    character(len=4),  parameter :: fyaml_brackets = "{}[]"

    ! The separator for categories (stored in var_name)
    character(len=1),  parameter :: fyaml_category_separator = "%"

    ! The default string for data that is not yet stored
    character(len=22), parameter :: unstored_data_string="__UNSTORED_DATA_STRING"

end module fyaml_constants
