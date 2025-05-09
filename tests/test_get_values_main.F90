!> \brief Test program for retrieving multiple YAML values
!>
!> \details Tests the ability to retrieve sequence values from a YAML document,
!> validating that arrays of different data types can be extracted correctly.
program test_get_values_main
  use test_utils, only: test_get_values, ERR_SUCCESS
  implicit none
  integer :: status
  status = test_get_values()
  if (status /= ERR_SUCCESS) error stop
end program test_get_values_main
