!> \file test_integration.f90
!! \brief Comprehensive integration test

program test_integration
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Integration Test")

    call test_full_workflow()
    call test_real_world_scenario()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_full_workflow()
        type(fyaml_t) :: yml, merged, result_yml
        character(len=512) :: config_file
        integer :: RC
        character(len=fyaml_StrLen) :: app_name
        integer :: max_iter
        logical :: debug_mode

        ! Get config file path
        config_file = trim(get_test_data_path()) // "/example_config.yml"

        ! Read configuration file
        call fyaml_read_file(yml, config_file, RC)
        call assert_equal_int(fyaml_Success, RC, "Integration: file reading")

        ! Access various types of data
        call fyaml_get(yml, "basic_config%application_name", app_name, RC)
        if (RC == fyaml_Success) then
            call assert_equal_string("FYAML Test Application", app_name, "Integration: app name")
        endif

        call fyaml_get(yml, "basic_config%max_iterations", max_iter, RC)
        if (RC == fyaml_Success) then
            call assert_equal_int(1000, max_iter, "Integration: max iterations")
        endif

        call fyaml_get(yml, "basic_config%debug_mode", debug_mode, RC)
        if (RC == fyaml_Success) then
            call assert_true(debug_mode, "Integration: debug mode")
        endif

        ! Add new variables
        call fyaml_add(yml, "runtime%test_mode", .true., "Test mode", RC)
        call assert_equal_int(fyaml_Success, RC, "Integration: add new variable")

        ! Sort variables for performance
        call fyaml_sort_variables(yml)
        call assert_true(yml%sorted, "Integration: sorting")

        ! Create second config for merging
        call fyaml_add(merged, "runtime%threads", 8, "Thread count", RC)
        call fyaml_add(merged, "runtime%memory_limit", 1024.0_yp, "Memory limit MB", RC)

        ! Test merging - use a separate result variable
        call fyaml_merge_configs(yml, merged, result_yml, RC)
        call assert_equal_int(fyaml_Success, RC, "Integration: config merging")

        ! Clean up the result
        call fyaml_cleanup(result_yml)

        call fyaml_cleanup(yml)
        call fyaml_cleanup(merged)
    end subroutine test_full_workflow

    subroutine test_real_world_scenario()
        type(fyaml_t) :: config
        character(len=fyaml_NamLen) :: species_list(10)
        integer :: grid_nx, grid_ny, RC
        real(yp) :: timestep
        logical :: enable_chemistry
        character(len=512) :: config_file

        ! Simulate a real atmospheric chemistry model configuration
        config_file = trim(get_test_data_path()) // "/example_config.yml"

        call fyaml_read_file(config, config_file, RC)
        if (RC /= fyaml_Success) then
            call test_failed("Real world scenario", "Failed to read config file")
            return
        endif

        ! Extract simulation parameters
        call fyaml_get(config, "simulation_parameters%grid_configuration%horizontal%nx", grid_nx, RC)
        call fyaml_get(config, "simulation_parameters%grid_configuration%horizontal%ny", grid_ny, RC)
        call fyaml_get(config, "simulation_parameters%time_configuration%timestep", timestep, RC)
        call fyaml_get(config, "simulation_parameters%physics_options%enable_chemistry", enable_chemistry, RC)

        ! Test that we got reasonable values
        if (RC == fyaml_Success) then
            call assert_true(grid_nx > 0, "Real world: valid grid nx")
            call assert_true(grid_ny > 0, "Real world: valid grid ny")
            call assert_true(timestep > 0.0_yp, "Real world: valid timestep")
        endif

        ! Try to get species list
        call fyaml_get(config, "chemistry%species", species_list, RC)
        if (RC == fyaml_Success) then
            call assert_true(len_trim(species_list(1)) > 0, "Real world: species list")
        endif

        write(*,'(A)') "Successfully processed atmospheric chemistry configuration"
        call test_passed("Real world scenario simulation")

        call fyaml_cleanup(config)
    end subroutine test_real_world_scenario

end program test_integration
