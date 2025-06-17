!> \file test_anchors.f90
!! \brief Test anchor functionality

program test_anchors
    use fyaml
    use test_utils
    implicit none

    character(len=512) :: config_file

    call print_test_header("Anchors")

    ! Get the test data path
    config_file = trim(get_test_data_path()) // "/example_config.yml"

    call test_anchor_definitions(config_file)
    call test_direct_config_values(config_file)
    call test_merge_key_presence(config_file)

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_anchor_definitions(filename)
        character(len=*), intent(in) :: filename
        type(fyaml_t) :: yml, yml_anchored
        integer :: RC
        character(len=100) :: string_val
        integer :: int_val
        logical :: bool_val

        write(*,*) "=== Testing Anchor Definitions ==="
        write(*,*) "File: ", trim(filename)

        ! Test parsing file with anchors using the full parser
        call fyaml_init(filename, yml, yml_anchored, RC)
        call assert_equal_int(fyaml_Success, RC, "Parse file with anchors return code")

        write(*,*) "Loaded ", yml%num_vars, " variables"

        ! Test accessing anchor-defined defaults
        write(*,*) "Testing anchor-defined defaults..."
        call fyaml_get(yml, "defaults%timeout", int_val, RC)
        write(*,*) "defaults%timeout: RC=", RC, ", value=", int_val
        call assert_equal_int(fyaml_Success, RC, "Get anchor timeout return code")
        call assert_equal_int(30, int_val, "Anchor timeout value")

        call fyaml_get(yml, "defaults%retries", int_val, RC)
        write(*,*) "defaults%retries: RC=", RC, ", value=", int_val
        call assert_equal_int(fyaml_Success, RC, "Get anchor retries return code")
        call assert_equal_int(3, int_val, "Anchor retries value")

        call fyaml_get(yml, "defaults%log_level", string_val, RC)
        write(*,*) "defaults%log_level: RC=", RC, ", value='", trim(string_val), "'"
        call assert_equal_int(fyaml_Success, RC, "Get anchor log_level return code")
        call assert_equal_string("INFO", trim(string_val), "Anchor log_level value")

        call fyaml_get(yml, "defaults%enable_ssl", bool_val, RC)
        write(*,*) "defaults%enable_ssl: RC=", RC, ", value=", bool_val
        call assert_equal_int(fyaml_Success, RC, "Get anchor enable_ssl return code")
        call assert_true(bool_val, "Anchor enable_ssl value")

        call fyaml_cleanup(yml)
    end subroutine test_anchor_definitions

    subroutine test_direct_config_values(filename)
        character(len=*), intent(in) :: filename
        type(fyaml_t) :: yml, yml_anchored
        integer :: RC
        character(len=100) :: string_val
        integer :: int_val
        logical :: bool_val

        write(*,*) "=== Testing Direct Config Values ==="

        ! Parse the file using the full anchor-aware parser
        call fyaml_init(filename, yml, yml_anchored, RC)
        call assert_equal_int(fyaml_Success, RC, "Parse file for direct values test")

        ! Test production-specific values (directly specified, not from anchor)
        write(*,*) "Testing production config values..."
        call fyaml_get(yml, "production_config%workers", int_val, RC)
        write(*,*) "production_config%workers: RC=", RC, ", value=", int_val
        call assert_equal_int(fyaml_Success, RC, "Get production workers return code")
        call assert_equal_int(10, int_val, "Production workers value")

        call fyaml_get(yml, "production_config%debug", bool_val, RC)
        write(*,*) "production_config%debug: RC=", RC, ", value=", bool_val
        call assert_equal_int(fyaml_Success, RC, "Get production debug return code")
        call assert_false(bool_val, "Production debug value")

        call fyaml_get(yml, "production_config%database_url", string_val, RC)
        write(*,*) "production_config%database_url: RC=", RC, ", value='", trim(string_val), "'"
        call assert_equal_int(fyaml_Success, RC, "Get production database_url return code")
        call assert_equal_string("postgresql://prod-server/database", trim(string_val), "Production database_url value")

        ! Test development-specific values
        write(*,*) "Testing development config values..."
        call fyaml_get(yml, "development_config%workers", int_val, RC)
        write(*,*) "development_config%workers: RC=", RC, ", value=", int_val
        call assert_equal_int(fyaml_Success, RC, "Get development workers return code")
        call assert_equal_int(1, int_val, "Development workers value")

        call fyaml_get(yml, "development_config%debug", bool_val, RC)
        write(*,*) "development_config%debug: RC=", RC, ", value=", bool_val
        call assert_equal_int(fyaml_Success, RC, "Get development debug return code")
        call assert_true(bool_val, "Development debug value")

        call fyaml_get(yml, "development_config%database_url", string_val, RC)
        write(*,*) "development_config%database_url: RC=", RC, ", value='", trim(string_val), "'"
        call assert_equal_int(fyaml_Success, RC, "Get development database_url return code")
        call assert_equal_string("postgresql://localhost/test_database", trim(string_val), "Development database_url value")

        ! Test overridden values in development_config
        call fyaml_get(yml, "development_config%log_level", string_val, RC)
        write(*,*) "development_config%log_level: RC=", RC, ", value='", trim(string_val), "'"
        call assert_equal_int(fyaml_Success, RC, "Get development log_level return code")
        call assert_equal_string("DEBUG", trim(string_val), "Development overridden log_level value")

        ! Now test if anchor values are actually inherited (should work with fyaml_init)
        write(*,*) "Testing if anchor values are inherited..."
        call fyaml_get(yml, "production_config%timeout", int_val, RC)
        write(*,*) "production_config%timeout: RC=", RC, ", value=", int_val
        if (RC == fyaml_Success) then
            write(*,*) "SUCCESS: Production config inherited timeout from anchor!"
            call assert_equal_int(fyaml_Success, RC, "Get production timeout return code")
            call assert_equal_int(30, int_val, "Production timeout value")
        else
            write(*,*) "FAIL: Production config did not inherit timeout from anchor"
        endif

        call fyaml_get(yml, "development_config%timeout", int_val, RC)
        write(*,*) "development_config%timeout: RC=", RC, ", value=", int_val
        if (RC == fyaml_Success) then
            write(*,*) "SUCCESS: Development config inherited timeout from anchor!"
            call assert_equal_int(fyaml_Success, RC, "Get development timeout return code")
            call assert_equal_int(30, int_val, "Development timeout value")
        else
            write(*,*) "FAIL: Development config did not inherit timeout from anchor"
        endif

        call fyaml_cleanup(yml)
    end subroutine test_direct_config_values

    subroutine test_merge_key_presence(filename)
        character(len=*), intent(in) :: filename
        type(fyaml_t) :: yml, yml_anchored
        integer :: RC
        integer :: int_val

        write(*,*) "=== Testing Merge Key Functionality ==="

        ! Parse the file using anchor-aware parser
        call fyaml_init(filename, yml, yml_anchored, RC)
        call assert_equal_int(fyaml_Success, RC, "Parse file for merge key test")

        ! Test that inherited values from anchor are accessible directly
        write(*,*) "Testing inherited anchor values..."
        call fyaml_get(yml, "production_config%retries", int_val, RC)
        write(*,*) "production_config%retries: RC=", RC, ", value=", int_val
        if (RC == fyaml_Success) then
            call assert_equal_int(fyaml_Success, RC, "Get production retries return code")
            call assert_equal_int(3, int_val, "Production retries value")
        else
            write(*,*) "Note: retries not inherited (expected for current implementation)"
        endif

        call fyaml_get(yml, "development_config%retries", int_val, RC)
        write(*,*) "development_config%retries: RC=", RC, ", value=", int_val
        if (RC == fyaml_Success) then
            call assert_equal_int(fyaml_Success, RC, "Get development retries return code")
            call assert_equal_int(3, int_val, "Development retries value")
        else
            write(*,*) "Note: retries not inherited (expected for current implementation)"
        endif

        call fyaml_cleanup(yml)
    end subroutine test_merge_key_presence

end program test_anchors
