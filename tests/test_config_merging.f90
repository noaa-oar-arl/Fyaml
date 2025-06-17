!> \file test_config_merging.f90
!! \brief Test configuration merging functionality

program test_config_merging
    use fyaml
    use test_utils
    implicit none

    call print_test_header("Config Merging")

    call test_basic_merging()
    call test_overwrite_merging()
    call test_empty_config_merging()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_basic_merging()
        type(fyaml_t) :: config1, config2, merged
        integer :: RC
        character(len=fyaml_StrLen) :: string_val
        integer :: int_val

        ! Create first config
        call fyaml_add(config1, "app%name", "TestApp", "Application name", RC)
        call fyaml_add(config1, "app%version", "1.0", "Version", RC)
        call fyaml_add(config1, "debug", .true., "Debug mode", RC)

        ! Create second config
        call fyaml_add(config2, "app%author", "FYAML Team", "Author", RC)
        call fyaml_add(config2, "max_threads", 4, "Max threads", RC)
        call fyaml_add(config2, "timeout", 30.0_yp, "Timeout", RC)

        ! Merge configs
        call fyaml_merge_configs(config1, config2, merged, RC)
        call assert_equal_int(fyaml_Success, RC, "Config merging return code")

        ! Verify merged content contains all variables
        call fyaml_get(merged, "app%name", string_val, RC)
        call assert_equal_int(fyaml_Success, RC, "Get merged app name")
        call assert_equal_string("TestApp", string_val, "Merged app name value")

        call fyaml_get(merged, "app%author", string_val, RC)
        call assert_equal_int(fyaml_Success, RC, "Get merged app author")
        call assert_equal_string("FYAML Team", string_val, "Merged app author value")

        call fyaml_get(merged, "max_threads", int_val, RC)
        call assert_equal_int(fyaml_Success, RC, "Get merged max_threads")
        call assert_equal_int(4, int_val, "Merged max_threads value")

        ! Check total number of variables
        call assert_true(merged%num_vars >= 5, "Merged config has all variables")

        call fyaml_cleanup(config1)
        call fyaml_cleanup(config2)
        call fyaml_cleanup(merged)
    end subroutine test_basic_merging

    subroutine test_overwrite_merging()
        type(fyaml_t) :: config1, config2, merged
        integer :: RC
        character(len=fyaml_StrLen) :: string_val

        ! Create configs with overlapping keys
        call fyaml_add(config1, "app%name", "OriginalApp", "Original name", RC)
        call fyaml_add(config1, "app%version", "1.0", "Version", RC)

        call fyaml_add(config2, "app%name", "UpdatedApp", "Updated name", RC)
        call fyaml_add(config2, "app%build", "123", "Build number", RC)

        ! Merge configs (config2 should overwrite config1)
        call fyaml_merge_configs(config1, config2, merged, RC)
        call assert_equal_int(fyaml_Success, RC, "Overwrite merging return code")

        ! Verify that config2 values take precedence
        call fyaml_get(merged, "app%name", string_val, RC)
        call assert_equal_string("UpdatedApp", string_val, "Overwritten app name")

        ! Verify that non-overlapping values are preserved
        call fyaml_get(merged, "app%version", string_val, RC)
        call assert_equal_string("1.0", string_val, "Preserved version")

        call fyaml_get(merged, "app%build", string_val, RC)
        call assert_equal_string("123", string_val, "New build number")

        call fyaml_cleanup(config1)
        call fyaml_cleanup(config2)
        call fyaml_cleanup(merged)
    end subroutine test_overwrite_merging

    subroutine test_empty_config_merging()
        type(fyaml_t) :: config1, config2, merged
        integer :: RC
        character(len=fyaml_StrLen) :: string_val

        ! Create one config with data, one empty
        call fyaml_add(config1, "test%value", "hello", "Test value", RC)
        ! config2 is empty (just initialized)

        ! Merge with empty config
        call fyaml_merge_configs(config1, config2, merged, RC)
        call assert_equal_int(fyaml_Success, RC, "Empty config merging return code")

        ! Verify data is preserved
        call fyaml_get(merged, "test%value", string_val, RC)
        call assert_equal_string("hello", string_val, "Value preserved from non-empty config")

        call fyaml_cleanup(config1)
        call fyaml_cleanup(config2)
        call fyaml_cleanup(merged)

        ! Test merging empty config with data config
        call fyaml_add(config2, "test%value2", "world", "Test value 2", RC)
        ! config1 is now empty

        call fyaml_merge_configs(config1, config2, merged, RC)
        call assert_equal_int(fyaml_Success, RC, "Reverse empty config merging return code")

        call fyaml_get(merged, "test%value2", string_val, RC)
        call assert_equal_string("world", string_val, "Value from second config")

        call fyaml_cleanup(config1)
        call fyaml_cleanup(config2)
        call fyaml_cleanup(merged)
    end subroutine test_empty_config_merging

end program test_config_merging
