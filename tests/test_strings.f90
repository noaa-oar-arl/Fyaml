!> \file test_strings.f90
!! \brief Test string functionality

program test_strings
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Strings")
    call test_passed("String test placeholder")
    call print_test_result()

end program test_strings
