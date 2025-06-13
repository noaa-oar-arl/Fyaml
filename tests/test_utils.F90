!> \file test_utils.f90
!! \brief Utility functions for FYAML tests
!!
!! This module provides common functionality used across all FYAML tests
!! including assertion functions, test data paths, and test reporting.

module test_utils
    use fyaml
    implicit none
    private

    public :: assert_equal_int, assert_equal_real, assert_equal_string, assert_equal_logical
    public :: assert_true, assert_false, assert_not_equal_int
    public :: test_passed, test_failed, get_test_data_path
    public :: print_test_header, print_test_result
    public :: tests_run, tests_passed, tests_failed

    ! Test counters
    integer, save :: tests_run = 0
    integer, save :: tests_passed = 0
    integer, save :: tests_failed = 0

contains

    !> \brief Print test header
    subroutine print_test_header(test_name)
        character(len=*), intent(in) :: test_name
        write(*,'(A)') "=========================================="
        write(*,'(A,A)') "Running test: ", trim(test_name)
        write(*,'(A)') "=========================================="
    end subroutine print_test_header

    !> \brief Print test results summary
    subroutine print_test_result()
        write(*,'(A)') "=========================================="
        write(*,'(A,I0,A,I0,A,I0)') "Tests run: ", tests_run, ", Passed: ", tests_passed, ", Failed: ", tests_failed
        if (tests_failed == 0) then
            write(*,'(A)') "ALL TESTS PASSED!"
        else
            write(*,'(A)') "SOME TESTS FAILED!"
        endif
        write(*,'(A)') "=========================================="
    end subroutine print_test_result

    !> \brief Mark a test as passed
    subroutine test_passed(test_name)
        character(len=*), intent(in) :: test_name
        tests_run = tests_run + 1
        tests_passed = tests_passed + 1
        write(*,'(A,A,A)') "✓ PASS: ", trim(test_name)
    end subroutine test_passed

    !> \brief Mark a test as failed
    subroutine test_failed(test_name, message)
        character(len=*), intent(in) :: test_name
        character(len=*), intent(in), optional :: message
        tests_run = tests_run + 1
        tests_failed = tests_failed + 1
        write(*,'(A,A)') "✗ FAIL: ", trim(test_name)
        if (present(message)) then
            write(*,'(A,A)') "       ", trim(message)
        endif
    end subroutine test_failed

    !> \brief Get test data directory path
    function get_test_data_path() result(path)
        character(len=512) :: path
        character(len=512) :: env_path

        ! Try to get from environment variable first
        call get_environment_variable("FYAML_TEST_DATA_DIR", env_path)
        if (len_trim(env_path) > 0) then
            path = trim(env_path)
        else
            ! Default path relative to build directory
            path = "../../test_data"
        endif
    end function get_test_data_path

    !> \brief Assert that two integers are equal
    subroutine assert_equal_int(expected, actual, test_name)
        integer, intent(in) :: expected, actual
        character(len=*), intent(in) :: test_name

        if (expected == actual) then
            call test_passed(test_name)
        else
            write(*,'(A,I0,A,I0)') "Expected: ", expected, ", Actual: ", actual
            call test_failed(test_name, "Integer values not equal")
        endif
    end subroutine assert_equal_int

    !> \brief Assert that two integers are not equal
    subroutine assert_not_equal_int(not_expected, actual, test_name)
        integer, intent(in) :: not_expected, actual
        character(len=*), intent(in) :: test_name

        if (not_expected /= actual) then
            call test_passed(test_name)
        else
            write(*,'(A,I0)') "Value should not be: ", not_expected
            call test_failed(test_name, "Integer values should not be equal")
        endif
    end subroutine assert_not_equal_int

    !> \brief Assert that two reals are equal (within tolerance)
    subroutine assert_equal_real(expected, actual, test_name, tolerance)
        real(yp), intent(in) :: expected, actual
        character(len=*), intent(in) :: test_name
        real(yp), intent(in), optional :: tolerance
        real(yp) :: tol

        tol = 1.0e-10_yp
        if (present(tolerance)) tol = tolerance

        if (abs(expected - actual) <= tol) then
            call test_passed(test_name)
        else
            write(*,'(A,ES15.8,A,ES15.8)') "Expected: ", expected, ", Actual: ", actual
            call test_failed(test_name, "Real values not equal within tolerance")
        endif
    end subroutine assert_equal_real

    !> \brief Assert that two strings are equal
    subroutine assert_equal_string(expected, actual, test_name)
        character(len=*), intent(in) :: expected, actual
        character(len=*), intent(in) :: test_name

        if (trim(expected) == trim(actual)) then
            call test_passed(test_name)
        else
            write(*,'(A,A,A,A)') "Expected: '", trim(expected), "', Actual: '", trim(actual), "'"
            call test_failed(test_name, "String values not equal")
        endif
    end subroutine assert_equal_string

    !> \brief Assert that two logicals are equal
    subroutine assert_equal_logical(expected, actual, test_name)
        logical, intent(in) :: expected, actual
        character(len=*), intent(in) :: test_name

        if (expected .eqv. actual) then
            call test_passed(test_name)
        else
            write(*,'(A,L1,A,L1)') "Expected: ", expected, ", Actual: ", actual
            call test_failed(test_name, "Logical values not equal")
        endif
    end subroutine assert_equal_logical

    !> \brief Assert that a logical is true
    subroutine assert_true(actual, test_name)
        logical, intent(in) :: actual
        character(len=*), intent(in) :: test_name

        if (actual) then
            call test_passed(test_name)
        else
            call test_failed(test_name, "Expected true, got false")
        endif
    end subroutine assert_true

    !> \brief Assert that a logical is false
    subroutine assert_false(actual, test_name)
        logical, intent(in) :: actual
        character(len=*), intent(in) :: test_name

        if (.not. actual) then
            call test_passed(test_name)
        else
            call test_failed(test_name, "Expected false, got true")
        endif
    end subroutine assert_false

end module test_utils
