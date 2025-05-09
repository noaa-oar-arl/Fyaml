!> \brief Test program for accessing nested YAML structures
!>
!> \details Tests the ability to navigate and retrieve values from nested YAML structures
!> using path notation with '%' delimiters.
program test_nested_access_main
  use test_utils, only: test_nested_access, ERR_SUCCESS
  implicit none
  integer :: status
  status = test_nested_access()
  if (status /= ERR_SUCCESS) error stop
end program test_nested_access_main
