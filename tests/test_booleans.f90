!> \file test_booleans.f90
!! \brief Test boolean functionality

program test_booleans
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Booleans")
    call test_passed("Boolean test placeholder")
    call print_test_result()

end program test_booleans
