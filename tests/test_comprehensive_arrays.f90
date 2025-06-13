!> \file test_comprehensive_arrays.f90
!! \brief Comprehensive test coverage for arrays of various types and sizes

program test_comprehensive_arrays
    use fyaml
    use test_utils
    implicit none

    write(*, '(A)') "Starting comprehensive array tests..."

    call test_various_array_sizes()
    call test_edge_case_arrays()
    call test_multidimensional_like_arrays()
    call test_array_boundary_conditions()
    call test_array_operations_comprehensive()

    write(*, '(A)') "Comprehensive array tests completed successfully!"

contains

    !> Test arrays of various sizes
    subroutine test_various_array_sizes()
        type(fyaml_t) :: yml
        integer :: RC

        ! Single element arrays
        integer, dimension(1) :: int_single = [42]
        real(yp), dimension(1) :: real_single = [3.14_yp]
        logical, dimension(1) :: bool_single = [.true.]
        character(len=fyaml_StrLen), dimension(1) :: string_single

        ! Small arrays (5 elements)
        integer, dimension(5) :: int_small = [1, 2, 3, 4, 5]
        real(yp), dimension(5) :: real_small = [1.1_yp, 2.2_yp, 3.3_yp, 4.4_yp, 5.5_yp]
        logical, dimension(5) :: bool_small = [.true., .false., .true., .false., .true.]
        character(len=fyaml_StrLen), dimension(5) :: string_small

        ! Medium arrays (20 elements)
        integer, dimension(20) :: int_medium
        real(yp), dimension(20) :: real_medium
        logical, dimension(20) :: bool_medium
        character(len=fyaml_StrLen), dimension(20) :: string_medium

        ! Large arrays (50 elements)
        integer, dimension(50) :: int_large
        real(yp), dimension(50) :: real_large
        logical, dimension(50) :: bool_large

        integer :: i

        write(*, '(A)') "Testing various array sizes..."

        ! Initialize string arrays
        string_single(1) = "single"
        string_small = ["one  ", "two  ", "three", "four ", "five "]

        ! Initialize medium arrays
        do i = 1, 20
            int_medium(i) = i * 10
            real_medium(i) = real(i, yp) * 0.5_yp
            bool_medium(i) = mod(i, 2) == 0
            write(string_medium(i), '(A,I0)') "item", i
        end do

        ! Initialize large arrays
        do i = 1, 50
            int_large(i) = i * i
            real_large(i) = sqrt(real(i, yp))
            bool_large(i) = mod(i, 3) == 0
        end do

        ! Test single element arrays
        call fyaml_add(yml, "int_single", int_single, "Single int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add single int array")

        call fyaml_add(yml, "real_single", real_single, "Single real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add single real array")

        call fyaml_add(yml, "bool_single", bool_single, "Single bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add single bool array")

        call fyaml_add(yml, "string_single", string_single, "Single string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add single string array")

        ! Test small arrays
        call fyaml_add(yml, "int_small", int_small, "Small int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add small int array")

        call fyaml_add(yml, "real_small", real_small, "Small real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add small real array")

        call fyaml_add(yml, "bool_small", bool_small, "Small bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add small bool array")

        call fyaml_add(yml, "string_small", string_small, "Small string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add small string array")

        ! Test medium arrays
        call fyaml_add(yml, "int_medium", int_medium, "Medium int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add medium int array")

        call fyaml_add(yml, "real_medium", real_medium, "Medium real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add medium real array")

        call fyaml_add(yml, "bool_medium", bool_medium, "Medium bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add medium bool array")

        call fyaml_add(yml, "string_medium", string_medium, "Medium string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add medium string array")

        ! Test large arrays
        call fyaml_add(yml, "int_large", int_large, "Large int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large int array")

        call fyaml_add(yml, "real_large", real_large, "Large real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large real array")

        call fyaml_add(yml, "bool_large", bool_large, "Large bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large bool array")

        call fyaml_cleanup(yml)
    end subroutine test_various_array_sizes

    !> Test edge case arrays
    subroutine test_edge_case_arrays()
        type(fyaml_t) :: yml
        integer :: RC

        ! Arrays with extreme values
        integer, dimension(5) :: int_extreme = [huge(1), -huge(1), 0, 1, -1]
        real(yp), dimension(5) :: real_extreme = [huge(1.0_yp), -huge(1.0_yp), 0.0_yp, tiny(1.0_yp), -tiny(1.0_yp)]
        logical, dimension(5) :: bool_pattern = [.true., .true., .false., .false., .true.]
        character(len=fyaml_StrLen), dimension(5) :: string_special

        ! Arrays with repeated values
        integer, dimension(7) :: int_repeated = [42, 42, 42, 42, 42, 42, 42]
        real(yp), dimension(6) :: real_repeated = [3.14_yp, 3.14_yp, 3.14_yp, 3.14_yp, 3.14_yp, 3.14_yp]
        logical, dimension(8) :: bool_all_true = [.true., .true., .true., .true., .true., .true., .true., .true.]
        logical, dimension(4) :: bool_all_false = [.false., .false., .false., .false.]

        write(*, '(A)') "Testing edge case arrays..."

        ! Initialize special string arrays
        string_special(1) = ""           ! Empty string
        string_special(2) = "   "        ! Whitespace only
        string_special(3) = "a"          ! Single character
        string_special(4) = "very_long_string_name_with_underscores_and_numbers123"
        string_special(5) = "Special!@#$%^&*()Characters"

        call fyaml_add(yml, "int_extreme", int_extreme, "Extreme int values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add extreme int values")

        call fyaml_add(yml, "real_extreme", real_extreme, "Extreme real values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add extreme real values")

        call fyaml_add(yml, "bool_pattern", bool_pattern, "Boolean pattern", RC)
        call assert_equal_int(fyaml_Success, RC, "Add boolean pattern")

        call fyaml_add(yml, "string_special", string_special, "Special string cases", RC)
        call assert_equal_int(fyaml_Success, RC, "Add special string cases")

        ! Test repeated values
        call fyaml_add(yml, "int_repeated", int_repeated, "Repeated int values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add repeated int values")

        call fyaml_add(yml, "real_repeated", real_repeated, "Repeated real values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add repeated real values")

        call fyaml_add(yml, "bool_all_true", bool_all_true, "All true booleans", RC)
        call assert_equal_int(fyaml_Success, RC, "Add all true booleans")

        call fyaml_add(yml, "bool_all_false", bool_all_false, "All false booleans", RC)
        call assert_equal_int(fyaml_Success, RC, "Add all false booleans")

        call fyaml_cleanup(yml)
    end subroutine test_edge_case_arrays

    !> Test multidimensional-like arrays (flattened)
    subroutine test_multidimensional_like_arrays()
        type(fyaml_t) :: yml
        integer :: RC

        ! Simulate 2D arrays as 1D (common in scientific computing)
        integer, parameter :: rows = 3, cols = 4
        integer, dimension(rows*cols) :: matrix_like
        real(yp), dimension(rows*cols) :: real_matrix_like
        logical, dimension(rows*cols) :: bool_matrix_like

        integer :: i, j, idx

        write(*, '(A)') "Testing multidimensional-like arrays..."

        ! Initialize matrix-like arrays (row-major order)
        do i = 1, rows
            do j = 1, cols
                idx = (i-1)*cols + j
                matrix_like(idx) = i*10 + j
                real_matrix_like(idx) = real(i, yp) + real(j, yp)*0.1_yp
                bool_matrix_like(idx) = mod(i+j, 2) == 0
            end do
        end do

        call fyaml_add(yml, "matrix_like_int", matrix_like, "Matrix-like int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add matrix-like int array")

        call fyaml_add(yml, "matrix_like_real", real_matrix_like, "Matrix-like real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add matrix-like real array")

        call fyaml_add(yml, "matrix_like_bool", bool_matrix_like, "Matrix-like bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add matrix-like bool array")

        call fyaml_cleanup(yml)
    end subroutine test_multidimensional_like_arrays

    !> Test array boundary conditions and limits
    subroutine test_array_boundary_conditions()
        type(fyaml_t) :: yml
        integer :: RC

        ! Test with reasonable array sizes
        integer, parameter :: max_test_size = 100
        integer, dimension(max_test_size) :: large_int_array
        real(yp), dimension(max_test_size) :: large_real_array

        ! Arrays with specific patterns
        integer, dimension(20) :: fibonacci_like
        real(yp), dimension(20) :: geometric_sequence
        logical, dimension(20) :: alternating_pattern

        integer :: i

        write(*, '(A)') "Testing array boundary conditions..."

        ! Initialize large arrays
        do i = 1, max_test_size
            large_int_array(i) = i
            large_real_array(i) = real(i, yp) * 0.001_yp
        end do

        ! Initialize pattern arrays
        fibonacci_like(1) = 1
        fibonacci_like(2) = 1
        do i = 3, 20
            fibonacci_like(i) = fibonacci_like(i-1) + fibonacci_like(i-2)
        end do

        do i = 1, 20
            geometric_sequence(i) = 2.0_yp ** (i-1)
            alternating_pattern(i) = mod(i, 2) == 1
        end do

        ! Test large arrays
        call fyaml_add(yml, "large_int_array", large_int_array, "Large int boundary test", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large int boundary test")

        call fyaml_add(yml, "large_real_array", large_real_array, "Large real boundary test", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large real boundary test")

        ! Test pattern arrays
        call fyaml_add(yml, "fibonacci_like", fibonacci_like, "Fibonacci-like sequence", RC)
        call assert_equal_int(fyaml_Success, RC, "Add fibonacci-like sequence")

        call fyaml_add(yml, "geometric_sequence", geometric_sequence, "Geometric sequence", RC)
        call assert_equal_int(fyaml_Success, RC, "Add geometric sequence")

        call fyaml_add(yml, "alternating_pattern", alternating_pattern, "Alternating boolean pattern", RC)
        call assert_equal_int(fyaml_Success, RC, "Add alternating boolean pattern")

        call fyaml_cleanup(yml)
    end subroutine test_array_boundary_conditions

    !> Test comprehensive array operations (add, get, update)
    subroutine test_array_operations_comprehensive()
        type(fyaml_t) :: yml
        integer :: RC

        ! Test arrays for all operations
        integer, dimension(8) :: int_ops = [1, 2, 3, 4, 5, 6, 7, 8]
        integer, dimension(8) :: int_ops_result
        real(yp), dimension(6) :: real_ops = [1.1_yp, 2.2_yp, 3.3_yp, 4.4_yp, 5.5_yp, 6.6_yp]
        real(yp), dimension(6) :: real_ops_result
        logical, dimension(4) :: bool_ops = [.true., .false., .true., .false.]
        logical, dimension(4) :: bool_ops_result
        character(len=fyaml_StrLen), dimension(3) :: string_ops = ["alpha", "beta ", "gamma"]
        character(len=fyaml_StrLen), dimension(3) :: string_ops_result

        integer :: i

        write(*, '(A)') "Testing comprehensive array operations..."

        ! Test add operations
        call fyaml_add(yml, "ops_int", int_ops, "Operations int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add operations int array")

        call fyaml_add(yml, "ops_real", real_ops, "Operations real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add operations real array")

        call fyaml_add(yml, "ops_bool", bool_ops, "Operations bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add operations bool array")

        call fyaml_add(yml, "ops_string", string_ops, "Operations string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add operations string array")

        ! Test get operations
        call fyaml_get(yml, "ops_int", int_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get operations int array")
        do i = 1, size(int_ops)
            call assert_equal_int(int_ops(i), int_ops_result(i), "Compare int array element")
        end do

        call fyaml_get(yml, "ops_real", real_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get operations real array")
        do i = 1, size(real_ops)
            call assert_equal_real(real_ops(i), real_ops_result(i), "Compare real array element")
        end do

        call fyaml_get(yml, "ops_bool", bool_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get operations bool array")
        do i = 1, size(bool_ops)
            call assert_equal_logical(bool_ops(i), bool_ops_result(i), "Compare bool array element")
        end do

        call fyaml_get(yml, "ops_string", string_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get operations string array")
        do i = 1, size(string_ops)
            call assert_equal_string(trim(string_ops(i)), trim(string_ops_result(i)), "Compare string array element")
        end do

        ! Test update operations
        int_ops = int_ops * 2
        call fyaml_update(yml, "ops_int", int_ops)
        call fyaml_get(yml, "ops_int", int_ops_result, RC)
        do i = 1, size(int_ops)
            call assert_equal_int(int_ops(i), int_ops_result(i), "Compare updated int array element")
        end do

        real_ops = real_ops * 1.5_yp
        call fyaml_update(yml, "ops_real", real_ops)
        call fyaml_get(yml, "ops_real", real_ops_result, RC)
        do i = 1, size(real_ops)
            call assert_equal_real(real_ops(i), real_ops_result(i), "Compare updated real array element")
        end do

        bool_ops = .not. bool_ops
        call fyaml_update(yml, "ops_bool", bool_ops)
        call fyaml_get(yml, "ops_bool", bool_ops_result, RC)
        do i = 1, size(bool_ops)
            call assert_equal_logical(bool_ops(i), bool_ops_result(i), "Compare updated bool array element")
        end do

        ! Test string update
        string_ops(1) = "new_alpha"
        string_ops(2) = "new_beta"
        string_ops(3) = "new_gamma"
        call fyaml_update(yml, "ops_string", string_ops)
        call fyaml_get(yml, "ops_string", string_ops_result, RC)
        do i = 1, size(string_ops)
            call assert_equal_string(trim(string_ops(i)), trim(string_ops_result(i)), "Compare updated string array element")
        end do

        call fyaml_cleanup(yml)
    end subroutine test_array_operations_comprehensive
end program test_comprehensive_arrays
