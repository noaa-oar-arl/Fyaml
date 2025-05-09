!> \brief Test program for basic YAML data types
!>
!> \details Validates that the parser can correctly interpret different YAML data types
!> including strings, integers, reals, booleans, and null values.
program test_basic_types_main
    use test_utils, only: test_basic_types, ERR_SUCCESS
    implicit none
    integer :: status
    status = test_basic_types()
    if (status /= ERR_SUCCESS) error stop
end program test_basic_types_main
