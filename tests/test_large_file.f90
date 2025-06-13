!> \file test_large_file.f90
!! \brief Test performance with large files

program test_large_file
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Large File Performance")

    call test_large_config_creation()
    call test_many_variables()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_large_config_creation()
        type(fyaml_t) :: yml
        integer :: RC, i
        character(len=50) :: var_name
        real(yp) :: start_time, end_time

        call cpu_time(start_time)

        ! Create a config with many variables
        do i = 1, 1000
            write(var_name, '(A,I0)') "variable_", i
            call fyaml_add(yml, trim(var_name), real(i, yp), "Test variable", RC)
            if (RC /= fyaml_Success) then
                call test_failed("Large config creation", "Failed to add variable")
                return
            endif
        end do

        call cpu_time(end_time)
        write(*,'(A,F8.3,A)') "Created 1000 variables in ", end_time - start_time, " seconds"

        call assert_equal_int(1000, yml%num_vars, "Large config variable count")
        call test_passed("Large config creation performance")

        call fyaml_cleanup(yml)
    end subroutine test_large_config_creation

    subroutine test_many_variables()
        type(fyaml_t) :: yml
        integer :: RC, i
        character(len=50) :: var_name
        integer :: retrieved_value

        ! Add many variables
        do i = 1, 500
            write(var_name, '(A,I0)') "test_var_", i
            call fyaml_add(yml, trim(var_name), i, "Test variable", RC)
        end do

        ! Sort for faster access
        call fyaml_sort_variables(yml)

        ! Retrieve some variables to test access
        call fyaml_get(yml, "test_var_250", retrieved_value, RC)
        call assert_equal_int(fyaml_Success, RC, "Retrieve from large config")
        call assert_equal_int(250, retrieved_value, "Large config value retrieval")

        call fyaml_cleanup(yml)
    end subroutine test_many_variables

end program test_large_file
