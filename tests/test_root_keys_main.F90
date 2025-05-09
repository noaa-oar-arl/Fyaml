!> \brief Test program for retrieving YAML root keys
!>
!> \details Tests functionality to list all root-level keys in a YAML document,
!> verifying that the top-level structure is correctly identified.
program test_root_keys_main
    use test_utils, only: test_root_keys, ERR_SUCCESS
    implicit none
    integer :: status
    status = test_root_keys()
    if (status /= ERR_SUCCESS) error stop
end program test_root_keys_main
