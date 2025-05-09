!> \brief Test program for YAML value retrieval
!>
!> \details Tests the ability to retrieve individual values from a YAML document
!> using the get_value functionality.
program test_get_value_main
  use test_utils, only: test_get_value, ERR_SUCCESS
  implicit none
  integer :: status
  status = test_get_value()
  if (status /= ERR_SUCCESS) error stop
end program test_get_value_main
