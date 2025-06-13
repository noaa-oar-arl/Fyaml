!> \file test_sorting.f90
!! \brief Test sorting functionality

program test_sorting
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Sorting")

    call test_variable_sorting()
    call test_sorted_access()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_variable_sorting()
        type(fyaml_t) :: yml
        integer :: RC

        ! Add variables in random order
        call fyaml_add(yml, "zebra", 1, "Test", RC)
        call fyaml_add(yml, "apple", 2, "Test", RC)
        call fyaml_add(yml, "banana", 3, "Test", RC)
        call fyaml_add(yml, "cherry", 4, "Test", RC)

        ! Check that initially not sorted
        call assert_false(yml%sorted, "Initially not sorted")

        ! Sort variables
        call fyaml_sort_variables(yml)

        ! Check that now sorted
        call assert_true(yml%sorted, "After sorting marked as sorted")

        call fyaml_cleanup(yml)
    end subroutine test_variable_sorting

    subroutine test_sorted_access()
        type(fyaml_t) :: yml
        integer :: RC, value, ix

        ! Add many variables
        call fyaml_add(yml, "var_50", 50, "Test", RC)
        call fyaml_add(yml, "var_10", 10, "Test", RC)
        call fyaml_add(yml, "var_30", 30, "Test", RC)
        call fyaml_add(yml, "var_20", 20, "Test", RC)
        call fyaml_add(yml, "var_40", 40, "Test", RC)

        ! Sort for binary search
        call fyaml_sort_variables(yml)

        ! Test that we can still retrieve values
        call fyaml_get(yml, "var_30", value, RC)
        call assert_equal_int(fyaml_Success, RC, "Sorted access return code")
        call assert_equal_int(30, value, "Sorted access value")

        ! Test variable index lookup
        call fyaml_get_var_index(yml, "var_20", ix)
        call assert_not_equal_int(-1, ix, "Variable index found")

        call fyaml_cleanup(yml)
    end subroutine test_sorted_access

end program test_sorting
