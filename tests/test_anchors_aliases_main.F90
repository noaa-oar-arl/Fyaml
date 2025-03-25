program test_anchors_aliases_main
    use test_utils, only: test_anchors_aliases, ERR_SUCCESS
    implicit none
    integer :: status
    status = test_anchors_aliases()
    if (status /= ERR_SUCCESS) error stop
end program test_anchors_aliases_main
