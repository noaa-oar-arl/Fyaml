!> \brief Test program for handling multiple YAML documents
!>
!> \details Tests the parsing and access of multiple YAML documents within a single file,
!> ensuring that document boundaries are properly recognized and content is correctly organized.
program test_multiple_docs_main
  use test_utils, only: test_multiple_docs, ERR_SUCCESS
  implicit none
  integer :: status
  status = test_multiple_docs()
  if (status /= ERR_SUCCESS) error stop
end program test_multiple_docs_main
