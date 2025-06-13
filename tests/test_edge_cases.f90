program test_edge_cases
    use fyaml
    use test_utils
    implicit none

    integer :: RC

    write(*, '(A)') "Running FYAML edge case and error path tests..."

    call test_file_parse_errors()
    call test_variable_read_errors()
    call test_malformed_inputs()
    call test_boundary_conditions()

    write(*, '(A)') "All edge case tests completed!"

contains

    !> Test file parsing error paths
    subroutine test_file_parse_errors()
        type(fyaml_t) :: yml, yml_anchored
        character(len=*), parameter :: bad_file = "nonexistent_file.yml"
        character(len=*), parameter :: malformed_file = "malformed.yml"
        integer :: unit_num

        write(*, '(A)') "  Testing file parsing errors..."

        ! Test parsing nonexistent file
        call fyaml_init(bad_file, yml, yml_anchored, RC)
        ! Should fail but not crash

        ! Create a malformed YAML file
        open(newunit=unit_num, file=malformed_file, status='replace')
        write(unit_num, '(A)') "invalid: yaml: structure:"
        write(unit_num, '(A)') "  - unmatched brackets ["
        write(unit_num, '(A)') "  incomplete"
        close(unit_num)

        ! Try to parse malformed file
        call fyaml_init(malformed_file, yml, yml_anchored, RC)
        ! Should handle gracefully

        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)

        ! Clean up test file
        open(unit=99, file=malformed_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_file_parse_errors

    !> Test variable reading error conditions
    subroutine test_variable_read_errors()
        type(fyaml_t) :: yml
        character(len=*), parameter :: error_file = "error_test.yml"
        integer :: unit_num
        character(len=fyaml_StrLen) :: string_val
        integer :: int_val
        logical :: bool_val

        write(*, '(A)') "  Testing variable read errors..."

        ! Create a YAML file with problematic entries
        open(newunit=unit_num, file=error_file, status='replace')
        write(unit_num, '(A)') "good_var: 42"
        write(unit_num, '(A)') "empty_var:"
        write(unit_num, '(A)') "string_var: some_value"
        write(unit_num, '(A)') "malformed_array: [1, 2, 3"  ! Missing closing bracket
        close(unit_num)

        call fyaml_read_file(yml, error_file, RC)

        ! Try to read various problematic variables
        call fyaml_get(yml, "empty_var", string_val, RC)
        call fyaml_get(yml, "malformed_array", int_val, RC)

        ! Try type mismatches
        call fyaml_get(yml, "string_var", int_val, RC)  ! String as int
        call fyaml_get(yml, "good_var", bool_val, RC)   ! Int as bool

        call fyaml_cleanup(yml)

        ! Clean up test file
        open(unit=99, file=error_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_variable_read_errors

    !> Test malformed input handling
    subroutine test_malformed_inputs()
        type(fyaml_t) :: yml
        integer :: int_val

        write(*, '(A)') "  Testing malformed input handling..."

        ! Test adding variables with extremely long names or problematic characters
        call fyaml_add(yml, "", 42, "Empty name", RC)
        call fyaml_add(yml, "   whitespace_name   ", 42, "Whitespace name", RC)
        call fyaml_add(yml, "special!@#$%chars", 42, "Special chars", RC)

        ! Try to get variables with malformed names
        call fyaml_get(yml, "", int_val, RC)
        call fyaml_get(yml, "   ", int_val, RC)

        ! Test with very long variable names
        call fyaml_get(yml, repeat("a", 500), int_val, RC)

        call fyaml_cleanup(yml)
    end subroutine test_malformed_inputs

    !> Test boundary conditions
    subroutine test_boundary_conditions()
        type(fyaml_t) :: yml
        integer, parameter :: large_size = 1000
        integer, dimension(large_size) :: large_array
        integer :: i

        write(*, '(A)') "  Testing boundary conditions..."

        ! Test with very large arrays
        do i = 1, large_size
            large_array(i) = i
        end do

        call fyaml_add(yml, "large_array", large_array, "Very large array", RC)

        ! Test getting array size
        call fyaml_get_size(yml, "large_array", i, RC)

        ! Test with arrays that might exceed expected sizes
        call fyaml_get(yml, "large_array", large_array, RC)

        ! Test adding many variables to stress internal storage
        do i = 1, 100
            call fyaml_add(yml, "var_" // trim(adjustl(int_to_str(i))), i, "Stress test", RC)
        end do

        call fyaml_cleanup(yml)
    end subroutine test_boundary_conditions

    !> Helper function to convert integer to string
    function int_to_str(i) result(str)
        integer, intent(in) :: i
        character(len=20) :: str
        write(str, '(I0)') i
    end function int_to_str

end program test_edge_cases
