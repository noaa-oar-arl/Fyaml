!> \file test_comprehensive_arrays.f90
!! \brief Comprehensive test coverage for arrays of various types and sizes

program test_comprehensive_arrays
    use fyaml
    use test_utils
    implicit none

    integer :: RC

    write(*, '(A)') "Starting comprehensive array tests..."

    call test_various_array_sizes()
    call test_edge_case_arrays()
    call test_multidimensional_like_arrays()
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

        ! Small arrays
        integer, dimension(2) :: int_small = [10, 20]
        real(yp), dimension(2) :: real_small = [1.1_yp, 2.2_yp]
        logical, dimension(2) :: bool_small = [.true., .false.]
        character(len=fyaml_StrLen), dimension(2) :: string_small

        ! Medium arrays
        integer, dimension(10) :: int_medium
        real(yp), dimension(10) :: real_medium
        logical, dimension(10) :: bool_medium
        character(len=fyaml_StrLen), dimension(10) :: string_medium

        ! Large arrays
        integer, dimension(100) :: int_large
        real(yp), dimension(100) :: real_large
        logical, dimension(100) :: bool_large

        integer :: i

        write(*, '(A)') "  Testing arrays of various sizes..."

        ! Initialize string arrays
        string_single(1) = "single"
        string_small(1) = "first"
        string_small(2) = "second"

        do i = 1, 10
            int_medium(i) = i * 10
            real_medium(i) = real(i, yp) * 1.1_yp
            bool_medium(i) = mod(i, 2) == 1
            write(string_medium(i), '("item_", I0)') i
        end do

        do i = 1, 100
            int_large(i) = i
            real_large(i) = real(i, yp) / 100.0_yp
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

        ! Arrays with special string cases
        character(len=fyaml_StrLen), dimension(5) :: string_special

        ! Arrays with repeated values
        integer, dimension(7) :: int_repeated = [42, 42, 42, 42, 42, 42, 42]
        real(yp), dimension(4) :: real_repeated = [3.14159_yp, 3.14159_yp, 3.14159_yp, 3.14159_yp]
        logical, dimension(6) :: bool_all_true = [.true., .true., .true., .true., .true., .true.]
        logical, dimension(3) :: bool_all_false = [.false., .false., .false.]

        write(*, '(A)') "  Testing edge case arrays..."

        ! Initialize special strings
        string_special(1) = ""  ! Empty string
        string_special(2) = " "  ! Whitespace
        string_special(3) = "very_long_string_that_might_test_limits_of_string_handling"
        string_special(4) = "special!@#$%^&*()chars"
        string_special(5) = "normal_string"

        ! Test extreme value arrays
        call fyaml_add(yml, "int_extreme", int_extreme, "Extreme int values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add extreme int array")

        call fyaml_add(yml, "real_extreme", real_extreme, "Extreme real values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add extreme real array")

        call fyaml_add(yml, "bool_pattern", bool_pattern, "Boolean pattern", RC)
        call assert_equal_int(fyaml_Success, RC, "Add bool pattern array")

        call fyaml_add(yml, "string_special", string_special, "Special string cases", RC)
        call assert_equal_int(fyaml_Success, RC, "Add special string array")

        ! Test repeated value arrays
        call fyaml_add(yml, "int_repeated", int_repeated, "Repeated int values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add repeated int array")

        call fyaml_add(yml, "real_repeated", real_repeated, "Repeated real values", RC)
        call assert_equal_int(fyaml_Success, RC, "Add repeated real array")

        call fyaml_add(yml, "bool_all_true", bool_all_true, "All true booleans", RC)
        call assert_equal_int(fyaml_Success, RC, "Add all true bool array")

        call fyaml_add(yml, "bool_all_false", bool_all_false, "All false booleans", RC)
        call assert_equal_int(fyaml_Success, RC, "Add all false bool array")

        call fyaml_cleanup(yml)
    end subroutine test_edge_case_arrays

    !> Test arrays that simulate multidimensional behavior
    subroutine test_multidimensional_like_arrays()
        type(fyaml_t) :: yml
        integer :: RC

        ! Simulate 2D arrays as 1D (common in scientific computing)
        integer, parameter :: rows = 3, cols = 4
        integer, dimension(rows*cols) :: matrix_like
        real(yp), dimension(rows*cols) :: real_matrix_like
        logical, dimension(rows*cols) :: bool_matrix_like

        ! Initialize arrays
        integer :: i, j, idx

        write(*, '(A)') "  Testing multidimensional-like arrays..."

        idx = 1
        do i = 1, rows
            do j = 1, cols
                matrix_like(idx) = i * 10 + j
                real_matrix_like(idx) = real(i, yp) + real(j, yp) * 0.1_yp
                bool_matrix_like(idx) = mod(i + j, 2) == 0
                idx = idx + 1
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

        ! Test with maximum reasonable array sizes
        integer, parameter :: max_test_size = 1000
        integer, dimension(max_test_size) :: large_int_array
        real(yp), dimension(max_test_size) :: large_real_array

        ! Arrays with specific patterns
        integer, dimension(50) :: fibonacci_like
        real(yp), dimension(50) :: geometric_sequence
        logical, dimension(50) :: alternating_pattern

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
        do i = 3, 50
            fibonacci_like(i) = fibonacci_like(i-1) + fibonacci_like(i-2)
        end do

        do i = 1, 50
            geometric_sequence(i) = 2.0_yp ** (i-1)
            alternating_pattern(i) = mod(i, 2) == 1
        end do

        ! Test large arrays
        call fyaml_add(yml, "large_int_array", large_int_array, "Large int boundary test", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large int array")

        call fyaml_add(yml, "large_real_array", large_real_array, "Large real boundary test", RC)
        call assert_equal_int(fyaml_Success, RC, "Add large real array")

        ! Test pattern arrays
        call fyaml_add(yml, "fibonacci_like", fibonacci_like, "Fibonacci-like sequence", RC)
        call assert_equal_int(fyaml_Success, RC, "Add fibonacci-like array")

        call fyaml_add(yml, "geometric_sequence", geometric_sequence, "Geometric sequence", RC)
        call assert_equal_int(fyaml_Success, RC, "Add geometric sequence")

        call fyaml_add(yml, "alternating_pattern", alternating_pattern, "Alternating boolean pattern", RC)
        call assert_equal_int(fyaml_Success, RC, "Add alternating pattern")

        call fyaml_cleanup(yml)
    end subroutine test_array_boundary_conditions

    !> Test comprehensive array operations (add, get, update, add_get)
    subroutine test_array_operations_comprehensive()
        type(fyaml_t) :: yml
        integer :: RC

        ! Test arrays for all operations
        integer, dimension(8) :: int_ops = [1, 2, 3, 4, 5, 6, 7, 8]
        integer, dimension(8) :: int_ops_result
        real(yp), dimension(6) :: real_ops = [1.1_yp, 2.2_yp, 3.3_yp, 4.4_yp, 5.5_yp, 6.6_yp]
        real(yp), dimension(6) :: real_ops_result
        logical, dimension(5) :: bool_ops = [.true., .false., .true., .false., .true.]
        logical, dimension(5) :: bool_ops_result
        character(len=fyaml_StrLen), dimension(4) :: string_ops, string_ops_result

        write(*, '(A)') "  Testing comprehensive array operations..."

        ! Initialize string array
        string_ops(1) = "first"
        string_ops(2) = "second"
        string_ops(3) = "third"
        string_ops(4) = "fourth"

        ! Test add operations
        call fyaml_add(yml, "ops_int", int_ops, "Operations int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add ops int array")

        call fyaml_add(yml, "ops_real", real_ops, "Operations real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add ops real array")

        call fyaml_add(yml, "ops_bool", bool_ops, "Operations bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add ops bool array")

        call fyaml_add(yml, "ops_string", string_ops, "Operations string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add ops string array")

        ! Test get operations
        call fyaml_get(yml, "ops_int", int_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get ops int array")
        call assert_equal_int(int_ops(1), int_ops_result(1), "Get ops int array element 1")
        call assert_equal_int(int_ops(8), int_ops_result(8), "Get ops int array element 8")

        call fyaml_get(yml, "ops_real", real_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get ops real array")
        call assert_equal_real(real_ops(1), real_ops_result(1), "Get ops real array element 1")
        call assert_equal_real(real_ops(6), real_ops_result(6), "Get ops real array element 6")

        call fyaml_get(yml, "ops_bool", bool_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get ops bool array")
        call assert_equal_logical(bool_ops(1), bool_ops_result(1), "Get ops bool array element 1")
        call assert_equal_logical(bool_ops(5), bool_ops_result(5), "Get ops bool array element 5")

        call fyaml_get(yml, "ops_string", string_ops_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get ops string array")
        call assert_equal_string(trim(string_ops(1)), trim(string_ops_result(1)), "Get ops string array element 1")
        call assert_equal_string(trim(string_ops(4)), trim(string_ops_result(4)), "Get ops string array element 4")

        ! Test update operations
        int_ops = [10, 20, 30, 40, 50, 60, 70, 80]
        call fyaml_update(yml, "ops_int", int_ops)
        call fyaml_get(yml, "ops_int", int_ops_result, RC)
        call assert_equal_int(10, int_ops_result(1), "Update ops int array element 1")
        call assert_equal_int(80, int_ops_result(8), "Update ops int array element 8")

        real_ops = [10.1_yp, 20.2_yp, 30.3_yp, 40.4_yp, 50.5_yp, 60.6_yp]
        call fyaml_update(yml, "ops_real", real_ops)
        call fyaml_get(yml, "ops_real", real_ops_result, RC)
        call assert_equal_real(10.1_yp, real_ops_result(1), "Update ops real array element 1")
        call assert_equal_real(60.6_yp, real_ops_result(6), "Update ops real array element 6")

        bool_ops = [.false., .true., .false., .true., .false.]
        call fyaml_update(yml, "ops_bool", bool_ops)
        call fyaml_get(yml, "ops_bool", bool_ops_result, RC)
        call assert_equal_logical(.false., bool_ops_result(1), "Update ops bool array element 1")
        call assert_equal_logical(.false., bool_ops_result(5), "Update ops bool array element 5")

        string_ops(1) = "updated_first"
        string_ops(2) = "updated_second"
        string_ops(3) = "updated_third"
        string_ops(4) = "updated_fourth"
        call fyaml_update(yml, "ops_string", string_ops)
        call fyaml_get(yml, "ops_string", string_ops_result, RC)
        call assert_equal_string("updated_first", trim(string_ops_result(1)), "Update ops string array element 1")
        call assert_equal_string("updated_fourth", trim(string_ops_result(4)), "Update ops string array element 4")

        ! Test add_get operations with new arrays
        int_ops = [100, 200, 300, 400, 500, 600, 700, 800]
        call fyaml_add_get(yml, "new_ops_int", int_ops, "New ops int array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new ops int array")

        real_ops = [100.1_yp, 200.2_yp, 300.3_yp, 400.4_yp, 500.5_yp, 600.6_yp]
        call fyaml_add_get(yml, "new_ops_real", real_ops, "New ops real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new ops real array")

        bool_ops = [.true., .true., .false., .false., .true.]
        call fyaml_add_get(yml, "new_ops_bool", bool_ops, "New ops bool array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new ops bool array")

        string_ops(1) = "new_first"
        string_ops(2) = "new_second"
        string_ops(3) = "new_third"
        string_ops(4) = "new_fourth"
        call fyaml_add_get(yml, "new_ops_string", string_ops, "New ops string array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new ops string array")

        call fyaml_cleanup(yml)
    end subroutine test_array_operations_comprehensive

end program test_comprehensive_arrays
