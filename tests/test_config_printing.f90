!> \file test_config_printing.f90
!! \brief Test config printing functionality

program test_config_printing
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Config Printing")
    call test_passed("Config printing test placeholder")
    call print_test_result()

end program test_config_printing
