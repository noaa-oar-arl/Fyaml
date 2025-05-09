!> \brief Test program for YAML anchor and alias functionality
!>
!> \details Validates the proper handling of YAML anchors and aliases,
!> ensuring that anchored values can be referenced properly.
program test_anchors_aliases_main
    use test_utils, only: test_anchors_aliases, ERR_SUCCESS
    implicit none
    integer :: status
    status = test_anchors_aliases()
    if (status /= ERR_SUCCESS) error stop
end program test_anchors_aliases_main
