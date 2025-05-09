!> \brief Test program for basic YAML file loading
!>
!> \details Tests the basic functionality of loading a YAML file,
!> ensuring the parser can successfully open and read a file.
program test_basic_loading_main
    use test_utils, only: test_basic_loading, ERR_SUCCESS
    implicit none
    integer :: status
    status = test_basic_loading()
    if (status /= ERR_SUCCESS) error stop
end program test_basic_loading_main
